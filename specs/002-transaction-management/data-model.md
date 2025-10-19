# Data Model: Gestão de Transações

**Date**: 2025-10-18
**Feature**: Transaction Management System
**Branch**: `002-transaction-management`

## Overview

This document defines the database schema and domain model for the transaction management feature, including one-time transactions, recurring templates, transfers, and their relationships.

## Entity: Transaction

### Description
Represents a financial transaction (income or expense). Supports both one-time transactions and recurring templates that generate future transactions.

### Schema

```ruby
create_table :transactions do |t|
  # Core transaction data
  t.string :transaction_type, null: false  # 'income' or 'expense'
  t.integer :amount_cents, null: false     # Amount in cents (integer for precision)
  t.string :currency, default: 'BRL', null: false
  t.date :transaction_date, null: false    # Date of the transaction
  t.text :description, null: false         # User-provided description

  # Relationships
  t.references :account, null: false, foreign_key: true
  t.references :category, null: false, foreign_key: true
  t.references :user, null: false, foreign_key: true  # Creator

  # Recurring/Template fields
  t.boolean :is_template, default: false, null: false
  t.string :frequency  # 'monthly', 'bimonthly', 'quarterly', 'semiannual', 'annual' (null for one-time)
  t.date :start_date   # For templates: when recurrence begins (null for one-time)
  t.date :end_date     # For templates: when recurrence ends (null = indefinite)
  t.references :parent_transaction, foreign_key: { to_table: :transactions }  # Links to template
  t.datetime :effectuated_at  # Manual effectuation timestamp (null = auto by date)

  # Transfer linking
  t.references :linked_transaction, foreign_key: { to_table: :transactions }  # For transfer pairs

  # Audit trail
  t.references :editor, foreign_key: { to_table: :users }  # Last editor
  t.datetime :edited_at

  t.timestamps
end

# Indexes for performance
add_index :transactions, :transaction_date
add_index :transactions, :transaction_type
add_index :transactions, :category_id
add_index :transactions, :account_id
add_index :transactions, :user_id
add_index :transactions, :parent_transaction_id
add_index :transactions, [:is_template, :parent_transaction_id]
add_index :transactions, :linked_transaction_id
```

### Attributes

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `transaction_type` | string | NOT NULL, IN ('income', 'expense') | Type of transaction |
| `amount_cents` | integer | NOT NULL, > 0, <= 99999999999 | Amount in cents (R$ 0.01 to R$ 999,999,999.99) |
| `currency` | string | NOT NULL, DEFAULT 'BRL' | Currency code |
| `transaction_date` | date | NOT NULL | Date the transaction occurred/will occur |
| `description` | text | NOT NULL | User description of transaction |
| `account_id` | references | NOT NULL, FK to accounts | Account this transaction affects |
| `category_id` | references | NOT NULL, FK to categories | Category for classification |
| `user_id` | references | NOT NULL, FK to users | User who created transaction |
| `is_template` | boolean | NOT NULL, DEFAULT false | True if this is a recurring template |
| `frequency` | string | NULLABLE, IN frequencies | Recurrence frequency (templates only) |
| `start_date` | date | NULLABLE | Template recurrence start date |
| `end_date` | date | NULLABLE | Template recurrence end date (null = indefinite) |
| `parent_transaction_id` | references | NULLABLE, FK to transactions | Template that generated this transaction |
| `effectuated_at` | datetime | NULLABLE | Manual effectuation timestamp |
| `linked_transaction_id` | references | NULLABLE, FK to transactions | Linked transaction (for transfers) |
| `editor_id` | references | NULLABLE, FK to users | Last user who edited |
| `edited_at` | datetime | NULLABLE | Last edit timestamp |

### Validations

```ruby
class Transaction < ApplicationRecord
  # Enums
  enum transaction_type: { income: 'income', expense: 'expense' }
  enum frequency: {
    monthly: 'monthly',
    bimonthly: 'bimonthly',
    quarterly: 'quarterly',
    semiannual: 'semiannual',
    annual: 'annual'
  }

  # Money
  monetize :amount_cents

  # Associations
  belongs_to :account
  belongs_to :category
  belongs_to :user, optional: false
  belongs_to :editor, class_name: 'User', optional: true
  belongs_to :parent_transaction, class_name: 'Transaction', optional: true
  belongs_to :linked_transaction, class_name: 'Transaction', optional: true
  has_many :children, class_name: 'Transaction', foreign_key: :parent_transaction_id, dependent: :destroy

  # Validations
  validates :transaction_type, presence: true, inclusion: { in: transaction_types.keys }
  validates :amount_cents, presence: true,
                           numericality: {
                             only_integer: true,
                             greater_than: 0,
                             less_than_or_equal_to: 99999999999
                           }
  validates :transaction_date, presence: true
  validates :description, presence: true, length: { minimum: 3, maximum: 500 }
  validates :currency, presence: true, inclusion: { in: ['BRL'] }

  # Template-specific validations
  validates :frequency, presence: true, if: :is_template?
  validates :start_date, presence: true, if: :is_template?
  validates :end_date, comparison: { greater_than: :start_date }, allow_nil: true, if: :is_template?

  # Non-template validations
  validates :frequency, absence: true, unless: :is_template?
  validates :start_date, absence: true, unless: :is_template?
  validates :end_date, absence: true, unless: :is_template?
  validates :parent_transaction_id, absence: true, if: :is_template?

  # Category/Account active validations
  validate :category_not_archived
  validate :account_not_archived

  private

  def category_not_archived
    errors.add(:category, 'está arquivada') if category&.archived?
  end

  def account_not_archived
    errors.add(:account, 'está arquivada') if account&.archived?
  end
end
```

### Scopes

```ruby
# Type scopes
scope :income, -> { where(transaction_type: 'income') }
scope :expense, -> { where(transaction_type: 'expense') }

# Template scopes
scope :templates, -> { where(is_template: true) }
scope :one_time, -> { where(is_template: false, parent_transaction_id: nil) }
scope :generated_from_template, -> { where.not(parent_transaction_id: nil) }

# Effectuation scopes (timezone-aware)
scope :effectuated, -> {
  tz = Time.find_zone('America/Sao_Paulo')
  where("effectuated_at IS NOT NULL OR transaction_date <= ?", tz.now.to_date)
}
scope :pending, -> {
  tz = Time.find_zone('America/Sao_Paulo')
  where("effectuated_at IS NULL AND transaction_date > ?", tz.now.to_date)
}

# Transfer scopes
scope :transfers, -> { joins(:category).where(categories: { name: 'Transferência' }) }

# Date scopes
scope :by_month, ->(month_string) {
  date = Date.parse(month_string)
  where(transaction_date: date.beginning_of_month..date.end_of_month)
}
scope :in_period, ->(start_date, end_date) {
  where(transaction_date: start_date..end_date)
}

# Filtering scope
scope :apply_filters, ->(filters) {
  result = all
  result = result.where(transaction_type: filters[:type]) if filters[:type].present?
  result = result.where(category_id: filters[:category_id]) if filters[:category_id].present?
  result = result.where(account_id: filters[:account_id]) if filters[:account_id].present?
  result = result.where("description ILIKE ?", "%#{filters[:search]}%") if filters[:search].present?

  if filters[:status] == 'effectuated'
    result = result.effectuated
  elsif filters[:status] == 'pending'
    result = result.pending
  end

  if filters[:period_start].present? && filters[:period_end].present?
    result = result.in_period(filters[:period_start], filters[:period_end])
  end

  result
}
```

### Callbacks

```ruby
# Balance recalculation
after_save :recalculate_account_balance
after_destroy :recalculate_account_balance

# Template regeneration
after_save :regenerate_future_transactions, if: :saved_change_to_template_attributes?

# Audit trail
before_update :set_editor, if: :will_save_change_to_any_attribute?

private

def recalculate_account_balance
  BalanceCalculator.recalculate(account)
end

def regenerate_future_transactions
  return unless is_template?
  TransactionService.regenerate_from_template(self)
end

def saved_change_to_template_attributes?
  is_template? && (
    saved_change_to_amount_cents? ||
    saved_change_to_description? ||
    saved_change_to_category_id? ||
    saved_change_to_frequency? ||
    saved_change_to_start_date? ||
    saved_change_to_end_date?
  )
end

def set_editor
  self.editor_id = Current.user&.id
  self.edited_at = Time.current
end
```

### Business Methods

```ruby
# Effectuation
def mark_as_paid!
  return if effectuated?
  update!(effectuated_at: Time.current)
end

def unmark_as_paid!
  return unless manually_effectuated? && pending_by_date?
  update!(effectuated_at: nil)
end

def effectuated?
  effectuated_at.present? || transaction_date <= Time.current.in_time_zone('America/Sao_Paulo').to_date
end

def manually_effectuated?
  effectuated_at.present?
end

def pending_by_date?
  transaction_date > Time.current.in_time_zone('America/Sao_Paulo').to_date
end

# Template operations
def template?
  is_template?
end

def generated?
  parent_transaction_id.present?
end

# Transfer operations
def transfer?
  category&.name == 'Transferência'
end

def transfer_pair?
  linked_transaction_id.present?
end
```

## Entity Relationships

### Transaction → Account
- **Type**: Many-to-One (belongs_to)
- **Constraint**: NOT NULL, FOREIGN KEY
- **Cascade**: No cascade delete (preserve transactions if account archived)
- **Description**: Every transaction belongs to exactly one account

### Transaction → Category
- **Type**: Many-to-One (belongs_to)
- **Constraint**: NOT NULL, FOREIGN KEY
- **Cascade**: No cascade delete (preserve transactions if category archived)
- **Description**: Every transaction belongs to exactly one category

### Transaction → User (Creator)
- **Type**: Many-to-One (belongs_to :user)
- **Constraint**: NOT NULL, FOREIGN KEY
- **Cascade**: No cascade delete (preserve audit trail)
- **Description**: Tracks which user created the transaction

### Transaction → User (Editor)
- **Type**: Many-to-One (belongs_to :editor)
- **Constraint**: NULLABLE, FOREIGN KEY
- **Cascade**: No cascade delete (preserve audit trail)
- **Description**: Tracks which user last edited the transaction

### Transaction → Transaction (Template-Children)
- **Type**: One-to-Many (has_many :children, belongs_to :parent_transaction)
- **Constraint**: NULLABLE, FOREIGN KEY, SELF-REFERENCE
- **Cascade**: CASCADE DELETE on children when template deleted
- **Description**: Templates generate multiple child transactions

### Transaction → Transaction (Transfer Linking)
- **Type**: One-to-One (belongs_to :linked_transaction)
- **Constraint**: NULLABLE, FOREIGN KEY, SELF-REFERENCE
- **Cascade**: Custom cascade (delete both when one deleted)
- **Description**: Transfer transactions linked in pairs

## State Transitions

### Recurring Transaction States

```
┌─────────────────┐
│  Template       │
│  (is_template)  │
└────────┬────────┘
         │ generates
         ▼
┌─────────────────────┐
│  Pending Generated  │────────────┐
│  (future date)      │            │
└─────────┬───────────┘            │
          │                        │
          │ date arrives           │ mark_as_paid!
          │ (automatic)            │
          │                        │
          ▼                        ▼
┌─────────────────────┐  ┌──────────────────────┐
│  Auto Effectuated   │  │  Manually Effectuated│
│  (date <= today)    │  │  (effectuated_at set)│
└─────────────────────┘  └──────────────────────┘
                                   │
                                   │ unmark (if date > today)
                                   ▼
                         ┌──────────────────────┐
                         │  Pending Generated   │
                         │  (back to pending)   │
                         └──────────────────────┘
```

**State Definitions**:
- **Template**: `is_template = true` - Generates future transactions
- **Pending Generated**: `parent_transaction_id != null AND effectuated_at = null AND transaction_date > today`
- **Auto Effectuated**: `transaction_date <= today` (regardless of effectuated_at)
- **Manually Effectuated**: `effectuated_at != null` (even if date > today)

**Transitions**:
1. Template creation → Generates all pending transactions (up to 12 months)
2. Date arrives → Auto effectuates (no DB update, scope-based)
3. Manual mark → Sets effectuated_at timestamp
4. Manual unmark → Clears effectuated_at (only if date > today)
5. Template edit → Regenerates pending transactions (deletes/recreates non-effectuated)
6. Template delete → Deletes pending transactions, keeps effectuated

## Data Integrity Rules

### Balance Consistency
- Account balance MUST equal: `initial_balance + SUM(income.amount) - SUM(expense.amount)`
- Transfers MUST NOT be counted in income/expense totals (exclude category "Transferência")
- Balance recalculated on: transaction create, update (amount/account change), destroy

### Transfer Integrity
- Transfer MUST create exactly 2 linked transactions
- Linked transactions MUST have:
  - Same `amount_cents`
  - Same `transaction_date`
  - Same `description`
  - Opposite accounts (origin vs destination)
  - Opposite types (expense vs income)
  - Category "Transferência"
  - `linked_transaction_id` pointing to each other
- Deleting one transfer transaction MUST delete the linked transaction

### Template Integrity
- Template (`is_template = true`) MUST have: `frequency`, `start_date`
- Template MUST NOT have: `parent_transaction_id`
- Generated transaction MUST have: `parent_transaction_id`
- Generated transaction MUST NOT have: `is_template = true`, `frequency`, `start_date`, `end_date`
- Effectuated transactions (date <= today OR effectuated_at != null) MUST NOT be modified by template edits

### Audit Trail
- `user_id` (creator) MUST be set on create, NEVER changed
- `editor_id` + `edited_at` MUST be set on every update
- Deleted transactions MUST be soft-deleted if audit trail required (NOT IMPLEMENTED in MVP)

## Sample Data

### One-time Expense
```ruby
Transaction.create!(
  transaction_type: 'expense',
  amount_cents: 15000, # R$ 150.00
  transaction_date: Date.today,
  description: 'Supermercado - compras da semana',
  account: checking_account,
  category: alimentacao_category,
  user: current_user,
  is_template: false
)
```

### Recurring Income Template (Monthly Salary)
```ruby
salary_template = Transaction.create!(
  transaction_type: 'income',
  amount_cents: 500000, # R$ 5.000,00
  transaction_date: Date.new(2025, 1, 5), # Not used for templates, but required
  description: 'Salário mensal',
  account: checking_account,
  category: salario_category,
  user: current_user,
  is_template: true,
  frequency: 'monthly',
  start_date: Date.new(2025, 1, 5),
  end_date: nil # Indefinite
)
# Generates: 2025-01-05, 2025-02-05, 2025-03-05, ..., 2025-12-05 (12 months)
```

### Transfer
```ruby
TransferService.create_transfer(
  from_account: checking_account,
  to_account: investment_account,
  amount_cents: 100000, # R$ 1.000,00
  transaction_date: Date.today,
  description: 'Aporte mensal em investimentos',
  user: current_user
)
# Creates 2 linked transactions:
# 1. Expense in checking_account
# 2. Income in investment_account
```

## Migration Strategy

### Phase 1: Core Schema
1. Create `transactions` table with all columns
2. Add indexes for performance
3. Add foreign key constraints
4. Seed "Transferência" category if not exists

### Phase 2: Data Population
- No migration needed (new feature, no existing data)

### Rollback Strategy
- Drop `transactions` table
- Remove "Transferência" category if unused

## Notes

- **Timezone Awareness**: All date comparisons for effectuation use `America/Sao_Paulo` timezone
- **Currency**: MVP is BRL-only, but schema supports future multi-currency via `currency` column
- **Soft Delete**: NOT implemented in MVP - transactions are hard-deleted for simplicity
- **Audit Trail**: Basic audit via `user_id`, `editor_id`, `edited_at` - can be enhanced with PaperTrail later
- **Performance**: Indexes on all filterable columns ensure <2s filter performance for 10k transactions
