# Data Model: Account Management

**Feature**: 001-account-management
**Date**: 2025-10-18
**Status**: Complete

## Entity Relationship Diagram

```
┌─────────────────────────────────┐
│          Family                 │
│─────────────────────────────────│
│ id: bigint (PK)                 │
│ created_at: datetime            │
│ updated_at: datetime            │
└─────────────────────────────────┘
         │
         │ has_many
         ├──────────────────────────────┐
         │                              │
         ▼                              ▼
┌─────────────────────────────────┐  ┌─────────────────────────────────┐
│          User                   │  │         Account                 │
│─────────────────────────────────│  │─────────────────────────────────│
│ id: bigint (PK)                 │  │ id: bigint (PK)                 │
│ email: string                   │  │ name: string (max 50)           │
│ encrypted_password: string      │  │ account_type: integer (enum)    │
│ family_id: bigint (FK) NN       │  │ initial_balance_cents: integer  │
│ role: integer (enum)            │  │ icon: string                    │
│ status: integer (enum)          │  │ color: string (hex)             │
│ created_at: datetime            │  │ archived_at: datetime           │
│ updated_at: datetime            │  │ family_id: bigint (FK) NN       │
│ ... (Devise fields)             │  │ created_at: datetime            │
└─────────────────────────────────┘  │ updated_at: datetime            │
         │                            └─────────────────────────────────┘
         │ belongs_to                          │
         └─────────────────────────────────────┘

Legend:
- PK = Primary Key
- FK = Foreign Key
- NN = NOT NULL constraint
```

## Entity Specifications

### 1. Family

**Purpose**: Groups users who share financial data (accounts, transactions, categories). Invisible to users in this phase but enables future multi-member family features.

**Table Name**: `families`

#### Columns

| Column Name  | Type      | Constraints                    | Description                          |
|-------------|-----------|--------------------------------|--------------------------------------|
| id          | bigint    | PRIMARY KEY, AUTO_INCREMENT    | Unique identifier                    |
| created_at  | datetime  | NOT NULL                       | Timestamp of family creation         |
| updated_at  | datetime  | NOT NULL                       | Timestamp of last update             |

#### Associations

- `has_many :users, dependent: :restrict_with_error`
- `has_many :accounts, dependent: :restrict_with_error`
- `has_many :categories, dependent: :destroy` (future phase)
- `has_many :transactions, through: :accounts` (future phase)

#### Validations

- No explicit validations (entity exists to group related data)

#### Indexes

```ruby
add_index :families, :created_at
```

#### Business Rules

- Created automatically during user signup (first user registration)
- Cannot be deleted if users or accounts exist (`restrict_with_error`)
- Single family per user in this phase (no family switching)
- Future: Support inviting additional family members

#### Scopes

- None required for this phase

---

### 2. Account

**Purpose**: Represents a financial account (checking or investment) that belongs to a family. Tracks initial balance and calculates current balance from transactions.

**Table Name**: `accounts`

#### Columns

| Column Name            | Type      | Constraints                           | Description                                    |
|-----------------------|-----------|---------------------------------------|------------------------------------------------|
| id                    | bigint    | PRIMARY KEY, AUTO_INCREMENT           | Unique identifier                              |
| name                  | string    | NOT NULL                              | Account display name (max 50 characters)       |
| account_type          | integer   | NOT NULL, DEFAULT: 0                  | Enum: 0=checking, 1=investment                 |
| initial_balance_cents | integer   | NOT NULL, DEFAULT: 0                  | Starting balance in cents (can be negative)    |
| icon                  | string    | NOT NULL                              | Emoji icon (🏦 for checking, 📈 for investment)|
| color                 | string    | NOT NULL                              | Hex color (#2563EB for checking, #10B981 for investment) |
| archived_at           | datetime  | NULL                                  | Soft delete timestamp (NULL = active)          |
| family_id             | bigint    | FOREIGN KEY, NOT NULL, INDEX          | References families.id                         |
| created_at            | datetime  | NOT NULL                              | Timestamp of account creation                  |
| updated_at            | datetime  | NOT NULL                              | Timestamp of last update                       |

#### Associations

- `belongs_to :family`
- `has_many :transactions, dependent: :restrict_with_error` (future phase)

#### Validations

```ruby
validates :name, presence: true, length: { maximum: 50 }
validates :account_type, presence: true
validates :initial_balance_cents, presence: true, numericality: { only_integer: true }
validates :icon, presence: true
validates :color, presence: true, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: "must be valid hex color" }
validates :family_id, presence: true
```

#### Indexes

```ruby
add_index :accounts, :family_id
add_index :accounts, :archived_at
add_index :accounts, [:family_id, :archived_at]  # Composite for active account queries
add_index :accounts, :created_at
```

#### Enums

```ruby
enum account_type: { checking: 0, investment: 1 }
```

#### Business Rules

- **Immutability**: `account_type` cannot be changed after creation
- **Soft Delete**: Use `archived_at` timestamp instead of hard delete
- **Balance Calculation**: Current balance = initial_balance + revenues - expenses (calculated dynamically, never stored)
- **Icon Assignment**:
  - Checking → 🏦 (bank emoji)
  - Investment → 📈 (chart increasing emoji)
- **Color Assignment**:
  - Checking → #2563EB (blue-600)
  - Investment → #10B981 (green-500)
- **Archiving Rules**:
  - Archived accounts excluded from default listings
  - Archived accounts included in historical reports
  - Archived accounts can be unarchived
  - Cannot delete account with existing transactions

#### Scopes

```ruby
scope :active, -> { where(archived_at: nil) }
scope :archived, -> { where.not(archived_at: nil) }
scope :checking, -> { where(account_type: :checking) }
scope :investment, -> { where(account_type: :investment) }
scope :ordered_by_creation, -> { order(created_at: :desc) }

# Optimized scope for list view with balance calculation
scope :with_balance_data, -> {
  left_joins(:transactions)
    .select('accounts.*')
    .select('SUM(CASE WHEN transactions.transaction_type = 0 AND transactions.date <= ? THEN transactions.amount_cents ELSE 0 END) as income_sum', Date.current)
    .select('SUM(CASE WHEN transactions.transaction_type = 1 AND transactions.date <= ? THEN transactions.amount_cents ELSE 0 END) as expense_sum', Date.current)
    .group('accounts.id')
}
```

#### Instance Methods

```ruby
# Calculate current balance (initial + income - expenses)
def current_balance
  effectuated_transactions = transactions.where('date <= ?', Date.current)
  balance_cents = initial_balance_cents +
                  effectuated_transactions.income.sum(:amount_cents) -
                  effectuated_transactions.expense.sum(:amount_cents)
  Money.new(balance_cents, 'BRL')
end

# Check if balance is positive
def positive_balance?
  current_balance.positive?
end

# Archive account (soft delete)
def archive!
  update(archived_at: Time.current)
end

# Unarchive account
def unarchive!
  update(archived_at: nil)
end

# Check if account is archived
def archived?
  archived_at.present?
end

# Display account type with icon
def type_with_icon
  "#{icon} #{account_type.humanize}"
end
```

#### Callbacks

```ruby
before_validation :set_icon_and_color, on: :create

private

def set_icon_and_color
  case account_type
  when 'checking'
    self.icon ||= '🏦'
    self.color ||= '#2563EB'
  when 'investment'
    self.icon ||= '📈'
    self.color ||= '#10B981'
  end
end
```

---

### 3. User (Extended)

**Purpose**: Existing Devise user model extended with family association. User automatically creates/joins family during signup.

**Table Name**: `users`

#### New Columns (Extension)

| Column Name  | Type    | Constraints                    | Description                     |
|-------------|---------|--------------------------------|---------------------------------|
| family_id   | bigint  | FOREIGN KEY, NOT NULL, INDEX   | References families.id          |

#### New Associations

- `belongs_to :family`
- `has_many :accounts, through: :family` (convenience accessor)

#### New Validations

```ruby
validates :family_id, presence: true
```

#### New Indexes

```ruby
add_index :users, :family_id
```

#### New Callbacks

```ruby
before_validation :create_family_if_needed, on: :create

private

def create_family_if_needed
  self.family ||= Family.create!
end
```

#### Business Rules

- Every user MUST belong to exactly one family
- Family created automatically during user signup
- First user in family is automatically admin (existing role logic)
- User cannot change family after signup (in this phase)

---

## Migration Sequence

### Migration 1: Create Families Table

```ruby
class CreateFamilies < ActiveRecord::Migration[7.2]
  def change
    create_table :families do |t|
      t.timestamps
    end

    add_index :families, :created_at
  end
end
```

### Migration 2: Add Family Reference to Users

```ruby
class AddFamilyToUsers < ActiveRecord::Migration[7.2]
  def change
    add_reference :users, :family, null: false, foreign_key: true, index: true

    # For existing users, create individual families
    reversible do |dir|
      dir.up do
        User.find_each do |user|
          user.update!(family: Family.create!)
        end
      end
    end
  end
end
```

### Migration 3: Create Accounts Table

```ruby
class CreateAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.integer :account_type, null: false, default: 0
      t.integer :initial_balance_cents, null: false, default: 0
      t.string :icon, null: false
      t.string :color, null: false
      t.datetime :archived_at
      t.references :family, null: false, foreign_key: true, index: true

      t.timestamps
    end

    add_index :accounts, :archived_at
    add_index :accounts, [:family_id, :archived_at]
    add_index :accounts, :created_at
  end
end
```

---

## Database Constraints Summary

### Foreign Keys
- `accounts.family_id → families.id` (ON DELETE: RESTRICT)
- `users.family_id → families.id` (ON DELETE: RESTRICT)

### Indexes (Performance Optimization)
- `families.created_at` - For chronological queries
- `accounts.family_id` - For family account lookups (most common query)
- `accounts.archived_at` - For filtering active/archived accounts
- `accounts.[family_id, archived_at]` - Composite for active accounts query
- `accounts.created_at` - For ordering by creation date
- `users.family_id` - For user-family association queries

### NOT NULL Constraints
- All primary keys
- All foreign keys (family_id)
- All timestamps (created_at, updated_at)
- Account fields: name, account_type, initial_balance_cents, icon, color

### Check Constraints (Optional - Database Level)
- `CHECK (LENGTH(accounts.name) <= 50)`
- `CHECK (accounts.color ~ '^#[0-9A-Fa-f]{6}$')` (PostgreSQL only)

---

## Data Seeding Strategy

### Development Seeds

```ruby
# db/seeds.rb extension

# Create test family with multiple accounts
family = Family.create!
user = User.find_or_create_by!(email: 'test@example.com') do |u|
  u.password = 'password'
  u.family = family
  u.role = :admin
  u.status = :active
end

# Seed checking accounts
Account.create!([
  {
    name: 'Nubank',
    account_type: :checking,
    initial_balance_cents: 150_000,  # R$ 1,500.00
    icon: '🏦',
    color: '#2563EB',
    family: family
  },
  {
    name: 'Bradesco',
    account_type: :checking,
    initial_balance_cents: 500_000,  # R$ 5,000.00
    icon: '🏦',
    color: '#2563EB',
    family: family
  }
])

# Seed investment accounts
Account.create!([
  {
    name: 'Tesouro Direto',
    account_type: :investment,
    initial_balance_cents: 1_000_000,  # R$ 10,000.00
    icon: '📈',
    color: '#10B981',
    family: family
  }
])

# Seed archived account (for testing archived view)
Account.create!(
  name: 'Conta Antiga',
  account_type: :checking,
  initial_balance_cents: 0,
  icon: '🏦',
  color: '#2563EB',
  archived_at: 1.month.ago,
  family: family
)

puts "✓ Seeded family #{family.id} with #{family.accounts.count} accounts (#{family.accounts.active.count} active, #{family.accounts.archived.count} archived)"
```

---

## Query Patterns (Common Operations)

### 1. List Active Accounts for Family

```ruby
# Controller
@accounts = current_user.family.accounts.active.ordered_by_creation
```

**SQL Generated**:
```sql
SELECT * FROM accounts
WHERE family_id = ? AND archived_at IS NULL
ORDER BY created_at DESC
```

### 2. Calculate Total Net Worth

```ruby
# Model method
def total_net_worth
  accounts.active.sum { |account| account.current_balance.cents }
end

# View helper
def formatted_net_worth(family)
  total_cents = family.accounts.active.sum { |account| account.current_balance.cents }
  number_to_currency(Money.new(total_cents, 'BRL'), locale: :'pt-BR')
end
```

### 3. Optimized Account List with Balances

```ruby
# Controller (avoids N+1 queries)
@accounts = current_user.family.accounts.active.with_balance_data.ordered_by_creation
```

**SQL Generated**:
```sql
SELECT accounts.*,
       SUM(CASE WHEN transactions.transaction_type = 0 AND transactions.date <= '2025-10-18' THEN transactions.amount_cents ELSE 0 END) as income_sum,
       SUM(CASE WHEN transactions.transaction_type = 1 AND transactions.date <= '2025-10-18' THEN transactions.amount_cents ELSE 0 END) as expense_sum
FROM accounts
LEFT OUTER JOIN transactions ON transactions.account_id = accounts.id
WHERE family_id = ? AND archived_at IS NULL
GROUP BY accounts.id
ORDER BY created_at DESC
```

### 4. Archive Account

```ruby
# Controller
account = current_user.family.accounts.find(params[:id])
account.archive!
```

**SQL Generated**:
```sql
UPDATE accounts
SET archived_at = '2025-10-18 12:00:00', updated_at = '2025-10-18 12:00:00'
WHERE id = ?
```

---

## Data Integrity Rules

### On Account Creation
1. Validate name presence and length (≤50 characters)
2. Assign icon and color based on account_type
3. Associate with current user's family
4. Initialize balance (can be positive, zero, or negative)
5. Set archived_at to NULL (active by default)

### On Account Edit
1. Allow changing: name, initial_balance_cents
2. Prohibit changing: account_type (immutable after creation)
3. Recalculate current_balance dynamically
4. Preserve family_id (cannot move account between families)

### On Account Archive
1. Set archived_at to current timestamp
2. Remove from active account listings
3. Preserve all transaction history
4. Include in historical reports for periods when account was active

### On Account Unarchive
1. Set archived_at to NULL
2. Restore to active account listings
3. Resume normal operation

### On Family Deletion
- **Prevent** if family has users (`restrict_with_error`)
- **Prevent** if family has accounts (`restrict_with_error`)
- Force explicit cleanup of related data before family deletion

---

## Performance Considerations

### Expected Load
- 50+ accounts per family (spec requirement)
- Multiple concurrent family members accessing same data
- Real-time updates via ActionCable broadcasts

### Optimization Strategies

1. **Composite Index** on `[family_id, archived_at]`:
   - Optimizes most common query: active accounts for a family
   - Reduces query time from O(n) to O(log n)

2. **Eager Loading** with `with_balance_data` scope:
   - Prevents N+1 queries when displaying account list with balances
   - Single SQL query instead of N queries (1 per account)

3. **Caching Strategy**:
   - Fragment caching on account list partial
   - Cache key includes family.updated_at + accounts.maximum(:updated_at)
   - Invalidate on account create/update/archive

4. **Database Hints**:
   - Use `SELECT ... FOR UPDATE` when calculating balances during concurrent transactions
   - Avoid row-level locking for read-only balance queries

---

## Testing Strategy

### Model Specs

#### Family Model
- ✓ Has many users
- ✓ Has many accounts
- ✓ Cannot be deleted with existing users
- ✓ Cannot be deleted with existing accounts

#### Account Model
- ✓ Validates presence of name
- ✓ Validates name length (max 50 characters)
- ✓ Validates presence of account_type
- ✓ Validates presence of initial_balance_cents
- ✓ Validates color format (hex color)
- ✓ Sets icon and color automatically on create
- ✓ Cannot change account_type after creation
- ✓ Calculates current_balance correctly
- ✓ Returns positive_balance? correctly
- ✓ Archives account (sets archived_at)
- ✓ Unarchives account (clears archived_at)
- ✓ Scopes: active, archived, checking, investment
- ✓ Orders by creation date descending

#### User Model (Extension)
- ✓ Belongs to family
- ✓ Creates family automatically on signup
- ✓ Validates presence of family_id
- ✓ Cannot save without family

### Factory Bot Fixtures

```ruby
# spec/factories/families.rb
FactoryBot.define do
  factory :family do
    # No attributes needed, just timestamps
  end
end

# spec/factories/accounts.rb
FactoryBot.define do
  factory :account do
    name { Faker::Bank.name }
    account_type { :checking }
    initial_balance_cents { rand(-100_000..500_000) }
    icon { '🏦' }
    color { '#2563EB' }
    association :family

    trait :checking do
      account_type { :checking }
      icon { '🏦' }
      color { '#2563EB' }
    end

    trait :investment do
      account_type { :investment }
      icon { '📈' }
      color { '#10B981' }
    end

    trait :archived do
      archived_at { 1.month.ago }
    end

    trait :negative_balance do
      initial_balance_cents { -50_000 }  # -R$ 500.00
    end
  end
end
```

---

## State Transitions

### Account Lifecycle

```
     [Create]
        ↓
   ┌─────────┐
   │ Active  │ ←──┐
   └─────────┘    │
        │         │
        │ archive!│ unarchive!
        ↓         │
   ┌──────────┐  │
   │ Archived │──┘
   └──────────┘

States:
- Active: archived_at IS NULL
- Archived: archived_at IS NOT NULL

Transitions:
- Create → Active (default state)
- Active → Archived (via archive! method)
- Archived → Active (via unarchive! method)

Prohibitions:
- Cannot transition to Deleted (soft delete only)
- Cannot change account_type (immutable)
```

---

## Audit Trail Integration

### PaperTrail Configuration

```ruby
# app/models/account.rb
class Account < ApplicationRecord
  has_paper_trail

  # Track who made changes (whodunnit)
  def user_for_paper_trail
    PaperTrail.request.whodunnit
  end
end

# Controller
class AccountsController < ApplicationController
  before_action :set_paper_trail_whodunnit

  private

  def set_paper_trail_whodunnit
    PaperTrail.request.whodunnit = current_user.id
  end
end
```

### Tracked Events
- Account creation (captures initial values)
- Account updates (captures changed attributes)
- Account archiving (captures archived_at change)
- Account unarchiving (captures archived_at cleared)

### Audit Queries

```ruby
# View account history
account.versions  # All versions
account.versions.last.changeset  # Most recent changes
account.versions.last.whodunnit  # Who made last change

# View user's account changes
PaperTrail::Version.where(item_type: 'Account', whodunnit: user.id)
```

---

## Summary

The data model implements three entities:

1. **Family**: Groups users and accounts (invisible to users)
2. **Account**: Financial accounts with balance calculation
3. **User**: Extended with family association

Key design decisions:
- ✓ Integer enums for account_type (performance)
- ✓ Integer cents for monetary values (precision)
- ✓ Soft delete via archived_at (reversible, audit-friendly)
- ✓ Dynamic balance calculation (single source of truth)
- ✓ Composite indexes for query optimization
- ✓ Automatic family creation during signup
- ✓ PaperTrail integration for audit trail

All entities follow Rails conventions, use appropriate constraints, and maintain referential integrity through foreign keys and validations.

**Status**: Data model complete, ready for contracts generation
