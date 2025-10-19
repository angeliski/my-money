# Quickstart: Gestão de Transações

**Date**: 2025-10-18
**Feature**: Transaction Management System
**Branch**: `002-transaction-management`

## Overview

This quickstart guide provides step-by-step instructions for implementing the transaction management feature. Follow these steps in order to build the complete feature from database to UI.

## Prerequisites

Before starting, ensure:
- [ ] Rails 7.2.2+ installed
- [ ] Ruby 3.3+ installed
- [ ] PostgreSQL (production) or SQLite3 (dev/test) configured
- [ ] Account management feature completed (dependency)
- [ ] Category system with "Transferência" category seeded
- [ ] User authentication (Devise) configured
- [ ] Hotwire (Turbo + Stimulus) configured
- [ ] Tailwind CSS configured
- [ ] money-rails gem installed and configured

## Phase 1: Database Schema (Estimated: 30 min)

### Step 1.1: Generate Transaction Model

```bash
bin/rails generate model Transaction \
  transaction_type:string \
  amount_cents:integer \
  currency:string \
  transaction_date:date \
  description:text \
  account:references \
  category:references \
  user:references \
  is_template:boolean \
  frequency:string \
  start_date:date \
  end_date:date \
  parent_transaction:references \
  effectuated_at:datetime \
  linked_transaction:references \
  editor:references \
  edited_at:datetime
```

**Expected Output**: `db/migrate/[timestamp]_create_transactions.rb`

### Step 1.2: Edit Migration

Edit the generated migration to add constraints and indexes:

```ruby
# db/migrate/[timestamp]_create_transactions.rb
class CreateTransactions < ActiveRecord::Migration[7.2]
  def change
    create_table :transactions do |t|
      # Core fields
      t.string :transaction_type, null: false
      t.integer :amount_cents, null: false
      t.string :currency, default: 'BRL', null: false
      t.date :transaction_date, null: false
      t.text :description, null: false

      # Relationships
      t.references :account, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      # Recurring/Template
      t.boolean :is_template, default: false, null: false
      t.string :frequency
      t.date :start_date
      t.date :end_date
      t.references :parent_transaction, foreign_key: { to_table: :transactions }
      t.datetime :effectuated_at

      # Transfer linking
      t.references :linked_transaction, foreign_key: { to_table: :transactions }

      # Audit
      t.references :editor, foreign_key: { to_table: :users }
      t.datetime :edited_at

      t.timestamps
    end

    # Performance indexes
    add_index :transactions, :transaction_date
    add_index :transactions, :transaction_type
    add_index :transactions, [:is_template, :parent_transaction_id]
  end
end
```

### Step 1.3: Run Migration

```bash
bin/rails db:migrate
bin/rails db:test:prepare
```

**Verification**: Check `db/schema.rb` contains `transactions` table

### Step 1.4: Seed "Transferência" Category

Add to `db/seeds.rb` if not already present:

```ruby
# Ensure "Transferência" category exists
Category.find_or_create_by!(name: 'Transferência') do |category|
  category.transaction_type = 'neutral'  # Or appropriate type
  category.icon = '💸'
end
```

Run: `bin/rails db:seed`

---

## Phase 2: Model Layer (Estimated: 45 min)

### Step 2.1: Configure Transaction Model

Edit `app/models/transaction.rb`:

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
  belongs_to :user
  belongs_to :editor, class_name: 'User', optional: true
  belongs_to :parent_transaction, class_name: 'Transaction', optional: true
  belongs_to :linked_transaction, class_name: 'Transaction', optional: true
  has_many :children, class_name: 'Transaction', foreign_key: :parent_transaction_id, dependent: :destroy

  # Scopes (see data-model.md for complete list)
  scope :templates, -> { where(is_template: true) }
  scope :effectuated, -> {
    tz = Time.find_zone('America/Sao_Paulo')
    where("effectuated_at IS NOT NULL OR transaction_date <= ?", tz.now.to_date)
  }
  scope :pending, -> {
    tz = Time.find_zone('America/Sao_Paulo')
    where("effectuated_at IS NULL AND transaction_date > ?", tz.now.to_date)
  }

  # Validations
  validates :transaction_type, presence: true
  validates :amount_cents, numericality: { greater_than: 0, less_than_or_equal_to: 99999999999 }
  validates :transaction_date, presence: true
  validates :description, presence: true, length: { minimum: 3, maximum: 500 }

  # Template-specific validations
  validates :frequency, presence: true, if: :is_template?
  validates :start_date, presence: true, if: :is_template?

  # Callbacks
  after_save :recalculate_account_balance
  after_destroy :recalculate_account_balance
  after_save :regenerate_future_transactions, if: :saved_change_to_template_attributes?

  # Business methods
  def mark_as_paid!
    update!(effectuated_at: Time.current) unless effectuated?
  end

  def unmark_as_paid!
    update!(effectuated_at: nil) if manually_effectuated? && pending_by_date?
  end

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
      saved_change_to_category_id?
    )
  end
end
```

### Step 2.2: Update Account Model

Add transaction association to `app/models/account.rb`:

```ruby
class Account < ApplicationRecord
  has_many :transactions, dependent: :restrict_with_error
  # ... existing code ...
end
```

### Step 2.3: Update Category Model

Add transaction association to `app/models/category.rb`:

```ruby
class Category < ApplicationRecord
  has_many :transactions, dependent: :restrict_with_error
  # ... existing code ...
end
```

---

## Phase 3: Service Layer (Estimated: 1 hour)

### Step 3.1: Create TransactionService

```bash
# Create service file manually (no generator)
touch app/services/transaction_service.rb
```

```ruby
# app/services/transaction_service.rb
class TransactionService
  def self.regenerate_from_template(template)
    # Delete existing pending non-manually-effectuated transactions
    template.children.pending.where(effectuated_at: nil).destroy_all

    # Calculate dates
    start_date = template.start_date
    end_date = template.end_date || 12.months.from_now.to_date
    dates = calculate_recurrence_dates(start_date, end_date, template.frequency)

    # Generate new transactions
    dates.each do |date|
      template.children.create!(
        transaction_type: template.transaction_type,
        amount_cents: template.amount_cents,
        transaction_date: date,
        description: template.description,
        category_id: template.category_id,
        account_id: template.account_id,
        user_id: template.user_id,
        is_template: false
      )
    end
  end

  private

  def self.calculate_recurrence_dates(start_date, end_date, frequency)
    dates = []
    current = start_date
    max_date = [end_date, 12.months.from_now.to_date].min

    while current <= max_date
      dates << current
      current = case frequency
        when 'monthly' then current + 1.month
        when 'bimonthly' then current + 2.months
        when 'quarterly' then current + 3.months
        when 'semiannual' then current + 6.months
        when 'annual' then current + 1.year
      end
    end

    dates
  end
end
```

### Step 3.2: Create TransferService

```bash
touch app/services/transfer_service.rb
```

```ruby
# app/services/transfer_service.rb
class TransferService
  def self.create_transfer(from_account:, to_account:, amount_cents:, transaction_date:, description:, user:, recurring: false, **recurring_params)
    transfer_category = Category.find_by!(name: 'Transferência')

    ActiveRecord::Base.transaction do
      # Create expense in source account
      expense = Transaction.create!(
        transaction_type: 'expense',
        amount_cents: amount_cents,
        transaction_date: transaction_date,
        description: description,
        account: from_account,
        category: transfer_category,
        user: user,
        is_template: recurring,
        frequency: recurring ? recurring_params[:frequency] : nil,
        start_date: recurring ? recurring_params[:start_date] : nil,
        end_date: recurring ? recurring_params[:end_date] : nil
      )

      # Create income in destination account
      income = Transaction.create!(
        transaction_type: 'income',
        amount_cents: amount_cents,
        transaction_date: transaction_date,
        description: description,
        account: to_account,
        category: transfer_category,
        user: user,
        is_template: recurring,
        frequency: recurring ? recurring_params[:frequency] : nil,
        start_date: recurring ? recurring_params[:start_date] : nil,
        end_date: recurring ? recurring_params[:end_date] : nil
      )

      # Link them
      expense.update!(linked_transaction: income)
      income.update!(linked_transaction: expense)

      [expense, income]
    end
  end
end
```

### Step 3.3: Create BalanceCalculator

```bash
touch app/services/balance_calculator.rb
```

```ruby
# app/services/balance_calculator.rb
class BalanceCalculator
  def self.recalculate(account)
    transfer_category = Category.find_by(name: 'Transferência')

    income = account.transactions
                    .where(transaction_type: 'income')
                    .where.not(category: transfer_category)
                    .sum(:amount_cents)

    expense = account.transactions
                     .where(transaction_type: 'expense')
                     .where.not(category: transfer_category)
                     .sum(:amount_cents)

    # Include transfers in balance but not in income/expense totals
    transfer_income = account.transactions
                             .where(transaction_type: 'income', category: transfer_category)
                             .sum(:amount_cents)

    transfer_expense = account.transactions
                              .where(transaction_type: 'expense', category: transfer_category)
                              .sum(:amount_cents)

    new_balance = account.initial_balance_cents + income - expense + transfer_income - transfer_expense

    account.update_column(:balance_cents, new_balance)
  end
end
```

---

## Phase 4: Controller & Routes (Estimated: 1 hour)

### Step 4.1: Generate Controller

```bash
bin/rails generate controller Transactions index new create edit update destroy
```

### Step 4.2: Configure Routes

Edit `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  resources :transactions do
    member do
      post :mark_as_paid
      delete :mark_as_paid, action: :unmark_as_paid
    end
  end

  resources :transfers, only: [:new, :create]
end
```

### Step 4.3: Implement TransactionsController

Edit `app/controllers/transactions_controller.rb` (see contracts/routes-contract.md for complete implementation)

**Key Actions**:
- `index`: List with filtering
- `new`: Modal form
- `create`: Turbo Stream response
- `edit`: Modal form
- `update`: Turbo Stream response
- `destroy`: Turbo Stream response
- `mark_as_paid`: Custom action
- `unmark_as_paid`: Custom action

### Step 4.4: Implement TransfersController

```bash
bin/rails generate controller Transfers new create
```

Implement in `app/controllers/transfers_controller.rb`

---

## Phase 5: Views & Frontend (Estimated: 2 hours)

### Step 5.1: Create Base Layout

Create view files:
```bash
mkdir -p app/views/transactions
touch app/views/transactions/index.html.erb
touch app/views/transactions/_form.html.erb
touch app/views/transactions/_transaction.html.erb
touch app/views/transactions/_filters.html.erb
```

Implement views following contracts/turbo-streams-contract.md

### Step 5.2: Create Stimulus Controllers

```bash
mkdir -p app/javascript/controllers
touch app/javascript/controllers/modal_controller.js
touch app/javascript/controllers/filter_controller.js
touch app/javascript/controllers/transaction_form_controller.js
```

Implement controllers following research.md patterns

### Step 5.3: Add Tailwind Styles

Update `app/assets/stylesheets/application.tailwind.css` if needed for custom animations

---

## Phase 6: Testing (Estimated: 3 hours)

### Step 6.1: Create FactoryBot Factory

```ruby
# spec/factories/transactions.rb
FactoryBot.define do
  factory :transaction do
    association :account
    association :category
    association :user

    transaction_type { 'expense' }
    amount_cents { 15000 }
    transaction_date { Date.today }
    description { 'Test transaction' }
    is_template { false }

    trait :income do
      transaction_type { 'income' }
    end

    trait :template do
      is_template { true }
      frequency { 'monthly' }
      start_date { Date.today }
    end

    trait :transfer do
      association :category, factory: :category, name: 'Transferência'
      association :linked_transaction, factory: :transaction
    end
  end
end
```

### Step 6.2: Write Model Specs

```bash
touch spec/models/transaction_spec.rb
```

Test: validations, associations, scopes, callbacks, business methods

### Step 6.3: Write Request Specs

```bash
touch spec/requests/transactions_spec.rb
```

Test: CRUD actions, filtering, Turbo Stream responses

### Step 6.4: Write System Specs

```bash
touch spec/system/transactions_spec.rb
```

Test: End-to-end user flows with browser automation

### Step 6.5: Write Service Specs

```bash
touch spec/services/transaction_service_spec.rb
touch spec/services/transfer_service_spec.rb
touch spec/services/balance_calculator_spec.rb
```

Test: Service business logic

### Step 6.6: Run Test Suite

```bash
bundle exec rspec
```

**Expected**: All tests pass, coverage ≥80%

---

## Phase 7: Quality Gates (Estimated: 30 min)

### Step 7.1: Run Quality Checks

```bash
bin/check
```

This runs:
1. RSpec tests
2. Rubocop linting
3. Brakeman security scan

### Step 7.2: Fix Any Issues

- Fix test failures
- Auto-fix Rubocop: `bundle exec rubocop -a`
- Address Brakeman warnings

### Step 7.3: Verify Coverage

Check `coverage/index.html` - ensure ≥80% coverage

---

## Phase 8: Browser Testing (Estimated: 1 hour)

### Step 8.1: Manual Browser Testing

Use Playwright MCP to test all user stories from spec.md:

1. User Story 1: One-time transactions
2. User Story 1.5: Transfers
3. User Story 2: Visualization & filtering
4. User Story 3: Recurring transactions
5. User Story 4: Template editing
6. User Story 5: Deletion

Test both desktop (1280px) and mobile (375px) viewports

### Step 8.2: Document Issues

Create checklist from spec.md acceptance scenarios, verify each passes

---

## Phase 9: Deployment Preparation (Estimated: 15 min)

### Step 9.1: Production Database Migration

Ensure migration runs on production database schema

### Step 9.2: Background Job Setup

Add to `config/schedule.rb` (if using whenever gem):

```ruby
every 1.day, at: '2:00 am' do
  runner "RegenerateRecurringTransactionsJob.perform_later"
end
```

Or set up via Sidekiq/DelayedJob scheduler

---

## Verification Checklist

Before marking complete, verify:

- [ ] All migrations run successfully
- [ ] Transaction model has all validations and associations
- [ ] Service objects handle recurring generation and transfers
- [ ] Controller actions return proper Turbo Stream responses
- [ ] Views render correctly on mobile and desktop
- [ ] Stimulus controllers handle modal and filter interactions
- [ ] All RSpec tests pass (≥80% coverage)
- [ ] Rubocop passes with no violations
- [ ] Brakeman reports no security issues
- [ ] Browser testing validates all 5 user stories
- [ ] Modal opens/closes smoothly without jarring UX
- [ ] Filters update list without full page reload
- [ ] Account balances update correctly on all operations
- [ ] Recurring transactions generate correctly
- [ ] Template edits only affect future pending transactions
- [ ] Transfers create two linked transactions correctly
- [ ] Manual mark as paid/unpaid works as expected

## Estimated Total Time

- Phase 1: 30 min
- Phase 2: 45 min
- Phase 3: 1 hour
- Phase 4: 1 hour
- Phase 5: 2 hours
- Phase 6: 3 hours
- Phase 7: 30 min
- Phase 8: 1 hour
- Phase 9: 15 min

**Total: ~10 hours** (single developer, uninterrupted)

## Common Issues & Solutions

### Issue: Modal doesn't close after form submit
**Solution**: Check Turbo Stream response includes `turbo_stream.remove("transaction_modal")`

### Issue: Balance not updating
**Solution**: Verify `recalculate_account_balance` callback is triggered, check BalanceCalculator logic

### Issue: Recurring transactions not generating
**Solution**: Check TransactionService logic, ensure start_date/frequency are valid

### Issue: Filter doesn't update list
**Solution**: Verify form has `data-turbo-frame="transactions_list"` attribute

### Issue: Tests failing with timezone issues
**Solution**: Ensure all date comparisons use `Time.find_zone('America/Sao_Paulo')`

## Next Steps

After completing this feature:
1. Run `/speckit.tasks` to generate implementation tasks
2. Run `/speckit.implement` to execute tasks
3. Create pull request for code review
4. Merge to main after approval
5. Deploy to production
