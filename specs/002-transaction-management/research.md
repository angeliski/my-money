# Research: Gestão de Transações

**Date**: 2025-10-18
**Feature**: Transaction Management System
**Branch**: `002-transaction-management`

## Overview

This document captures research findings for implementing the transaction management feature, focusing on critical technical decisions around Turbo Stream modals, recurring transaction patterns, money handling, and complex filtering with Hotwire.

## Research Areas

### 1. Turbo Frame/Stream Modal Patterns (Critical - User Input)

**Context**: User explicitly requested careful handling of modal-based transaction entry with Turbo Streams to avoid jarring or strange UX.

**Decision**: Use Turbo Frame for modal content with careful stream handling

**Rationale**:
- **Turbo Frame approach**: Wrap modal content in a `<turbo-frame id="transaction_modal">` that replaces itself when form is submitted
- **Avoid jarring transitions**: Use `data-turbo-action="replace"` instead of "advance" to prevent browser history pollution
- **Dismiss on success**: After successful create/update, return `turbo_stream.remove` for modal frame + `turbo_stream.prepend` for new transaction in list
- **Preserve on error**: On validation errors, return modal frame with errors rendered inline (no dismiss)
- **Animation handling**: Use CSS transitions on modal backdrop/content, triggered via Stimulus controller lifecycle callbacks

**Implementation Pattern**:
```ruby
# Controller action (create)
respond_to do |format|
  if @transaction.save
    format.turbo_stream do
      render turbo_stream: [
        turbo_stream.remove("transaction_modal"),
        turbo_stream.prepend("transactions_list", partial: "transactions/transaction", locals: { transaction: @transaction }),
        turbo_stream.update("account_balance", partial: "accounts/balance", locals: { account: @transaction.account })
      ]
    end
  else
    format.turbo_stream do
      render turbo_stream: turbo_stream.replace("transaction_modal", partial: "transactions/modal_form", locals: { transaction: @transaction })
    end
  end
end
```

**Stimulus Controller** (modal_controller.js):
```javascript
// Handles modal open/close animations and cleanup
connect() {
  this.element.showModal(); // Native <dialog> element
  this.element.addEventListener('close', this.handleClose.bind(this));
}

handleClose() {
  this.element.classList.add('closing'); // Trigger fade-out animation
  setTimeout(() => this.element.remove(), 200); // Remove after animation
}
```

**Alternatives Considered**:
- **Full page replacement**: Rejected - breaks mobile UX flow, requires re-rendering entire list
- **Separate modal route**: Rejected - adds complexity, harder to manage state
- **JavaScript-only modal**: Rejected - violates Hotwire-first principle, breaks without JS

**Best Practices Applied**:
1. Native `<dialog>` element for semantic HTML and accessibility
2. Turbo Frame targets modal content only, not entire page
3. Multiple Turbo Streams in single response for coordinated updates
4. Stimulus controller handles only UI concerns (animations, focus management)
5. Server returns complete HTML, no client-side templating

### 2. Recurring Transaction Generation Patterns

**Context**: System must generate up to 12 months of future transactions from recurring templates, update them when template changes, and mark them as "effectuated" when date arrives.

**Decision**: Eager generation with background regeneration job

**Rationale**:
- **Eager generation on create/update**: Generate all 12 months immediately when template is created/updated for instant visibility
- **Background job (daily)**: Scheduled job regenerates future transactions for templates approaching <12 month horizon
- **Effectuation via scope**: Use database query with timezone-aware date comparison, not status column updates
- **Template linkage**: `parent_transaction_id` column links generated transactions to template
- **Independence on effectuation**: Use `effectuated_at` timestamp - once set (manually or by date), transaction becomes independent

**Implementation Pattern**:

**Model** (transaction.rb):
```ruby
class Transaction < ApplicationRecord
  # Scopes
  scope :templates, -> { where(is_template: true) }
  scope :generated_from_template, -> { where.not(parent_transaction_id: nil) }
  scope :effectuated, -> {
    where("effectuated_at IS NOT NULL OR transaction_date <= ?", Time.current.in_time_zone("America/Sao_Paulo").to_date)
  }
  scope :pending, -> {
    where("effectuated_at IS NULL AND transaction_date > ?", Time.current.in_time_zone("America/Sao_Paulo").to_date)
  }

  # Callbacks
  after_save :regenerate_future_transactions, if: :is_template?

  def regenerate_future_transactions
    TransactionService.regenerate_from_template(self)
  end
end
```

**Service** (transaction_service.rb):
```ruby
class TransactionService
  def self.regenerate_from_template(template)
    # Delete existing pending transactions (not effectuated, not manually marked)
    template.children.pending.where(effectuated_at: nil).destroy_all

    # Generate new transactions
    start_date = template.start_date
    end_date = template.end_date || 12.months.from_now

    dates = calculate_recurrence_dates(start_date, end_date, template.frequency)
    dates.each do |date|
      template.children.create!(
        transaction_type: template.transaction_type,
        amount_cents: template.amount_cents,
        transaction_date: date,
        description: template.description,
        category_id: template.category_id,
        account_id: template.account_id,
        user_id: template.user_id,
        is_template: false,
        parent_transaction_id: template.id
      )
    end
  end

  private

  def self.calculate_recurrence_dates(start_date, end_date, frequency)
    dates = []
    current = start_date
    while current <= end_date && current <= 12.months.from_now.to_date
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

**Background Job** (regenerate_recurring_transactions_job.rb):
```ruby
class RegenerateRecurringTransactionsJob < ApplicationJob
  queue_as :default

  def perform
    Transaction.templates.find_each do |template|
      # Only regenerate if less than 12 months of future transactions exist
      future_count = template.children.pending.count
      if future_count < 12
        TransactionService.regenerate_from_template(template)
      end
    end
  end
end
```

**Alternatives Considered**:
- **Lazy generation (on-demand)**: Rejected - poor UX, users expect to see future transactions immediately
- **Status column for effectuation**: Rejected - adds mutable state, date comparison is source of truth
- **Update-in-place**: Rejected - requires tracking which transactions were modified, complex invalidation logic

**Best Practices Applied**:
1. Database scopes as single source of truth (no derived status columns)
2. Timezone-aware date comparisons using `Time.current.in_time_zone`
3. Service object pattern for complex business logic
4. Background job for maintenance tasks (regeneration)
5. Destroy dependent transactions on template delete with `dependent: :destroy`

### 3. Money-rails Best Practices for Transactions

**Context**: Project already uses `money-rails` gem configured with BRL currency and ROUND_HALF_UP rounding. Need to apply best practices for transaction amounts.

**Decision**: Use `monetize` helper with validations and careful formatting

**Rationale**:
- **Column naming**: Use `amount_cents` (integer) column, money-rails auto-converts to Money object
- **Monetize declaration**: `monetize :amount_cents` in model creates `amount` accessor returning Money object
- **Validations**: Validate `amount_cents` directly (integer), not `amount` (Money object)
- **Forms**: Accept decimal input, convert to cents automatically via `amount=` setter
- **Display**: Use `amount.format` for i18n-aware display (already configured for pt-BR)

**Implementation Pattern**:

**Migration**:
```ruby
class CreateTransactions < ActiveRecord::Migration[7.2]
  def change
    create_table :transactions do |t|
      t.integer :amount_cents, null: false
      t.string :currency, default: 'BRL', null: false
      # ... other columns
    end
  end
end
```

**Model** (transaction.rb):
```ruby
class Transaction < ApplicationRecord
  monetize :amount_cents

  validates :amount_cents, presence: true,
                           numericality: {
                             greater_than: 0,
                             less_than_or_equal_to: 99999999999 # R$ 999,999,999.99
                           }
end
```

**Form Helper**:
```erb
<%= form.number_field :amount,
                      step: 0.01,
                      min: 0.01,
                      max: 999999999.99,
                      class: "..." %>
```

**Display Helper** (transactions_helper.rb):
```ruby
module TransactionsHelper
  def format_transaction_amount(transaction)
    color = transaction.income? ? 'text-green-600' : 'text-red-600'
    sign = transaction.income? ? '+' : '-'

    content_tag(:span, class: color) do
      "#{sign} #{transaction.amount.format}"
    end
  end
end
```

**Alternatives Considered**:
- **Store as decimal**: Rejected - floating point precision issues, money-rails uses integers for accuracy
- **Manual cent conversion**: Rejected - error-prone, money-rails handles automatically
- **Separate currency column per transaction**: Rejected - app is BRL-only, unnecessary complexity

**Best Practices Applied**:
1. Integer storage (cents) for precision
2. Money object for all calculations and display
3. Validations on integer column (amount_cents), not Money accessor
4. money-rails automatic conversion handles form input
5. i18n-aware formatting via `amount.format`

### 4. Complex Filtering with Turbo

**Context**: Transaction list requires filtering by period, type, category, account, status, and text search - potentially combined filters - without full page reload.

**Decision**: Turbo Frame with query parameters and server-side filtering

**Rationale**:
- **Turbo Frame target**: Wrap transaction list in `<turbo-frame id="transactions_list">` that reloads on filter change
- **Form submission**: Filter form submits to index action with `data-turbo-frame="transactions_list"`, replacing only list content
- **Query parameters**: All filter params in URL for bookmarkability and browser history
- **Server-side filtering**: Use scopes and Ransack-style filtering, return filtered results
- **Stimulus controller**: Manages filter form state, auto-submit on change (debounced for text search)

**Implementation Pattern**:

**Controller** (transactions_controller.rb):
```ruby
class TransactionsController < ApplicationController
  def index
    @transactions = Transaction.accessible_by(current_user)
                               .apply_filters(filter_params)
                               .by_month(params[:month] || Date.current.strftime('%Y-%m'))
                               .includes(:account, :category)
                               .order(transaction_date: :desc, created_at: :desc)

    @transactions = @transactions.page(params[:page]).per(50) # Pagy

    respond_to do |format|
      format.html # Full page
      format.turbo_stream # Filter update - replace transactions_list frame
    end
  end

  private

  def filter_params
    params.permit(:type, :category_id, :account_id, :status, :search, :period_start, :period_end)
  end
end
```

**Model Scopes** (transaction.rb):
```ruby
class Transaction < ApplicationRecord
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
      result = result.where(transaction_date: filters[:period_start]..filters[:period_end])
    end

    result
  }

  scope :by_month, ->(month_string) {
    date = Date.parse(month_string)
    where(transaction_date: date.beginning_of_month..date.end_of_month)
  }
end
```

**View** (index.html.erb):
```erb
<div data-controller="filter">
  <%= form_with url: transactions_path, method: :get, data: {
        turbo_frame: "transactions_list",
        filter_target: "form",
        action: "input->filter#submit"
      } do |f| %>
    <%= f.select :type, [['Todas', ''], ['Receita', 'income'], ['Despesa', 'expense']] %>
    <%= f.select :category_id, Category.all.pluck(:name, :id), include_blank: 'Todas' %>
    <%= f.select :account_id, Account.all.pluck(:name, :id), include_blank: 'Todas' %>
    <%= f.select :status, [['Todas', ''], ['Realizada', 'effectuated'], ['Pendente', 'pending']] %>
    <%= f.text_field :search, placeholder: 'Buscar descrição...', data: { action: 'input->filter#debounceSubmit' } %>
  <% end %>

  <%= turbo_frame_tag "transactions_list" do %>
    <%= render partial: 'transactions/list', locals: { transactions: @transactions } %>
  <% end %>
</div>
```

**Stimulus Controller** (filter_controller.js):
```javascript
import { Controller } from "@hotwire/stimulus"

export default class extends Controller {
  static targets = ["form"]

  connect() {
    this.timeout = null
  }

  submit(event) {
    this.formTarget.requestSubmit()
  }

  debounceSubmit(event) {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.formTarget.requestSubmit()
    }, 300) // 300ms debounce for text search
  }
}
```

**Alternatives Considered**:
- **Client-side filtering**: Rejected - doesn't scale to 10k transactions, requires loading all data
- **AJAX with JSON**: Rejected - violates Hotwire-first principle, requires client-side templating
- **Separate filter modal**: Rejected - poor mobile UX, filters should be visible

**Best Practices Applied**:
1. Server-side filtering for scalability
2. Turbo Frame for partial page updates
3. URL query parameters for shareable/bookmarkable filters
4. Debounced text search to reduce server load
5. Scopes for composable filter logic
6. Eager loading (includes) to prevent N+1 queries

## Technology Additions

**New Dependencies**: None - all required gems already in project (money-rails, pagy, turbo-rails, stimulus-rails)

**Database Indexes Required**:
```ruby
add_index :transactions, :transaction_date
add_index :transactions, :transaction_type
add_index :transactions, :category_id
add_index :transactions, :account_id
add_index :transactions, :parent_transaction_id
add_index :transactions, [:is_template, :parent_transaction_id] # For templates and children queries
```

## Summary

All research complete with no unresolved clarifications:

1. ✅ **Modal UX**: Turbo Frame + native `<dialog>` + Stimulus for animations
2. ✅ **Recurring Logic**: Eager generation + background job + scope-based effectuation
3. ✅ **Money Handling**: money-rails with `amount_cents` integer column + validations
4. ✅ **Filtering**: Server-side scopes + Turbo Frame + debounced auto-submit

**Key Insights**:
- Turbo Streams can coordinate multiple DOM updates (modal dismiss + list prepend + balance update) in single response
- Scope-based effectuation (date comparison) eliminates mutable status column and race conditions
- money-rails handles all currency formatting, just validate integer cents
- Server-side filtering with Turbo Frames provides scalability without sacrificing Hotwire principles

**No blockers identified** - ready to proceed to Phase 1 (data model design).
