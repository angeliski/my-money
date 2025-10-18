# Research: Account Management Implementation

**Feature**: 001-account-management
**Date**: 2025-10-18
**Status**: Complete

## Research Questions

This document consolidates research findings to resolve all "NEEDS CLARIFICATION" items from the Technical Context section and to establish best practices for the implementation.

---

## 1. Rails Enum Best Practices for Account Type

### Decision
Use ActiveRecord enum with integer column for `account_type` field.

### Rationale
- **Performance**: Integer enums are more efficient than string columns (smaller storage, faster indexing)
- **Type Safety**: Rails enum provides type-safe access with methods like `account.checking?` and `account.investment?`
- **Scopes**: Automatic scope generation (`Account.checking`, `Account.investment`)
- **Validation**: Built-in validation prevents invalid values
- **Migration Safety**: Integer enums are easier to extend without breaking existing data

### Implementation Pattern
```ruby
# Migration
add_column :accounts, :account_type, :integer, null: false, default: 0

# Model
class Account < ApplicationRecord
  enum account_type: { checking: 0, investment: 1 }
end
```

### Alternatives Considered
- **String enums**: More readable in database but slower performance and larger storage
- **Separate STI classes**: Over-engineered for simple type distinction, complicates queries
- **PostgreSQL enum type**: Not available in SQLite3 (dev/test environments), limits portability

---

## 2. Hotwire Patterns for Real-Time Account Updates

### Decision
Use Turbo Frames for forms and Turbo Streams for list updates, combined with ActionCable broadcasts for family-wide synchronization.

### Rationale
- **Turbo Frames**: Isolate form interactions without full page reloads, perfect for create/edit modals
- **Turbo Streams**: Enable server-driven DOM updates for list items, balance totals, and status changes
- **ActionCable**: Broadcast account changes to all family members via WebSocket for real-time sync
- **Progressive Enhancement**: Works without JavaScript (falls back to full page reloads)
- **SEO-Friendly**: Server-rendered HTML maintains accessibility and search engine compatibility

### Implementation Pattern
```ruby
# Controller
def create
  @account = current_user.family.accounts.build(account_params)
  if @account.save
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.prepend("accounts-list", partial: "accounts/account", locals: { account: @account }),
          turbo_stream.replace("accounts-total", partial: "accounts/total", locals: { total: calculate_total })
        ]
      end
      format.html { redirect_to accounts_path }
    end

    # Broadcast to family members
    broadcast_update_to current_user.family
  end
end
```

```erb
<!-- View -->
<%= turbo_frame_tag "account-form" do %>
  <%= form_with model: @account, data: { turbo_frame: "_top" } do |f| %>
    <!-- form fields -->
  <% end %>
<% end %>

<div id="accounts-list">
  <%= turbo_stream_from "family_#{current_user.family_id}_accounts" %>
  <%= render @accounts %>
</div>
```

### Alternatives Considered
- **Full-page reloads**: Poor UX, slow on mobile networks
- **JSON API + JavaScript framework**: Over-engineered, breaks SEO, requires separate API layer
- **Polling**: Inefficient, high server load, delayed updates

---

## 3. Money-Rails Integration for Balance Calculations

### Decision
Use `money-rails` gem with `_cents` integer columns for all monetary values, configured for BRL currency with `ROUND_HALF_UP` rounding mode.

### Rationale
- **Precision**: Integer cents storage avoids floating-point rounding errors
- **Already Configured**: Project already uses money-rails in `config/initializers/money.rb`
- **I18n Integration**: Automatic formatting with pt-BR locale (R$ 1.500,00)
- **Calculations**: Safe arithmetic operations without precision loss
- **Database Compatibility**: Integer columns work in both SQLite3 and PostgreSQL

### Implementation Pattern
```ruby
# Migration
add_column :accounts, :initial_balance_cents, :integer, default: 0, null: false

# Model
class Account < ApplicationRecord
  monetize :initial_balance_cents

  def current_balance
    # Calculation: initial_balance + revenues - expenses
    balance_cents = initial_balance_cents +
                    transactions.revenue.sum(:amount_cents) -
                    transactions.expense.sum(:amount_cents)
    Money.new(balance_cents, "BRL")
  end

  def positive_balance?
    current_balance.positive?
  end
end
```

```erb
<!-- View -->
<%= number_to_currency(@account.current_balance, locale: :'pt-BR') %>
<!-- Outputs: R$ 1.500,00 -->
```

### Alternatives Considered
- **Decimal columns**: Risk of precision loss in calculations, not recommended for financial apps
- **BigDecimal**: More complex, money-rails provides better abstraction
- **Manual cents conversion**: Error-prone, reinventing the wheel

---

## 4. Soft Delete Pattern for Account Archiving

### Decision
Use timestamp-based soft delete with `archived_at` datetime column and ActiveRecord scopes.

### Rationale
- **Historical Integrity**: Maintains references for past transactions and reports
- **Reversible**: Users can unarchive accounts if needed
- **Audit Trail**: Preserves who archived and when (via PaperTrail integration)
- **Query Simplicity**: Default scope filters archived records, explicit scope shows all
- **Rails Convention**: Follows established Rails patterns (similar to Devise's deleted_at)

### Implementation Pattern
```ruby
# Migration
add_column :accounts, :archived_at, :datetime
add_index :accounts, :archived_at

# Model
class Account < ApplicationRecord
  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  def archive!
    update(archived_at: Time.current)
  end

  def unarchive!
    update(archived_at: nil)
  end

  def archived?
    archived_at.present?
  end
end

# Controller
def index
  @accounts = current_user.family.accounts.active
  @archived_accounts = current_user.family.accounts.archived if params[:show_archived]
end

def archive
  @account = current_user.family.accounts.find(params[:id])
  @account.archive!
  redirect_to accounts_path, notice: t('accounts.archived_successfully')
end
```

### Alternatives Considered
- **Boolean archived column**: Loses timestamp information, less informative
- **Paranoia gem**: Additional dependency, simple timestamp pattern is sufficient
- **acts_as_paranoid gem**: Overkill for this use case, adds complexity
- **Hard delete**: Violates financial integrity requirements, breaks historical reports

---

## 5. Family Creation During User Signup

### Decision
Extend Devise registration controller to automatically create Family record after user signup, associating user as the first family member and admin.

### Rationale
- **Invisible to Users**: Spec requirement that family concept is backend-only in this phase
- **Automatic Association**: Every user belongs to exactly one family from signup
- **Future-Proof**: Enables multi-member families later without schema changes
- **Single Responsibility**: Family model manages shared financial data scope
- **Security**: Family scope prevents cross-family data leakage

### Implementation Pattern
```ruby
# Migration
create_table :families do |t|
  t.timestamps
end

add_reference :users, :family, foreign_key: true, null: false

# Model: app/models/family.rb
class Family < ApplicationRecord
  has_many :users, dependent: :restrict_with_error
  has_many :accounts, dependent: :restrict_with_error
  has_many :categories, dependent: :destroy
end

# Model: app/models/user.rb (extend existing)
class User < ApplicationRecord
  belongs_to :family

  before_validation :create_family_if_needed, on: :create

  private

  def create_family_if_needed
    self.family ||= Family.create!
  end
end

# Alternative: Override Devise registration controller
class Users::RegistrationsController < Devise::RegistrationsController
  def create
    build_resource(sign_up_params)
    resource.build_family unless resource.family

    if resource.save
      # ... standard Devise flow
    end
  end
end
```

### Alternatives Considered
- **Manual family creation step**: Violates "invisible to user" requirement
- **Database trigger**: Less portable, harder to test, not Rails way
- **Service object**: Over-engineered for simple callback, complicates signup flow
- **Delayed family creation**: Creates edge case where user has no family, complicates queries

---

## 6. Balance Calculation Strategy

### Decision
Calculate balance dynamically via database query aggregation, cache result in-memory for display but never store in database column.

### Rationale
- **Single Source of Truth**: Balance always reflects actual transaction state
- **Consistency**: No risk of stale balance data after transaction changes
- **Audit Trail**: Historical balance can be reconstructed from transactions
- **Edit Safety**: Changing initial balance automatically recalculates correctly
- **Query Efficiency**: Database aggregation with indexes is fast enough for 50+ accounts

### Implementation Pattern
```ruby
# Model
class Account < ApplicationRecord
  has_many :transactions, dependent: :restrict_with_error

  def current_balance
    # Sum transactions that have been effectuated (date <= today)
    effectuated_transactions = transactions.where('date <= ?', Date.current)

    balance_cents = initial_balance_cents +
                    effectuated_transactions.income.sum(:amount_cents) -
                    effectuated_transactions.expense.sum(:amount_cents)

    Money.new(balance_cents, 'BRL')
  end

  # For list view optimization (eager load counts)
  scope :with_balance_data, -> {
    left_joins(:transactions)
      .select('accounts.*')
      .select('SUM(CASE WHEN transactions.transaction_type = 0 AND transactions.date <= ? THEN transactions.amount_cents ELSE 0 END) as income_sum', Date.current)
      .select('SUM(CASE WHEN transactions.transaction_type = 1 AND transactions.date <= ? THEN transactions.amount_cents ELSE 0 END) as expense_sum', Date.current)
      .group('accounts.id')
  }
end

# Controller (optimized query)
def index
  @accounts = current_user.family.accounts.active.with_balance_data
end

# View helper
def account_balance(account)
  if account.respond_to?(:income_sum)
    # Optimized path (eager loaded)
    balance_cents = account.initial_balance_cents +
                    (account.income_sum || 0) -
                    (account.expense_sum || 0)
    Money.new(balance_cents, 'BRL')
  else
    # Fallback to model method
    account.current_balance
  end
end
```

### Alternatives Considered
- **Cached balance column**: Risk of inconsistency, requires complex invalidation logic
- **Materialized view**: Over-engineered for this scale, complicates migrations
- **Counter cache**: Doesn't handle initial balance changes or transaction edits properly
- **Background job recalculation**: Adds complexity, delays updates, can still become inconsistent

---

## 7. Client-Side Validation with Stimulus

### Decision
Implement progressive enhancement with server-side validation as primary, Stimulus controller for instant feedback (no submit required).

### Rationale
- **Security**: Never trust client-side validation, always validate on server
- **UX Enhancement**: Instant feedback improves user experience
- **Accessibility**: Works without JavaScript (form still submits to server)
- **Mobile-Friendly**: Reduces round-trips on slow mobile networks
- **Rails Integration**: Stimulus controllers connect seamlessly with Rails UJS

### Implementation Pattern
```javascript
// app/javascript/controllers/account_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "nameError", "balance", "balanceError"]

  validateName(event) {
    const name = this.nameTarget.value.trim()

    if (name === "") {
      this.showError(this.nameErrorTarget, "Nome não pode ficar em branco")
      return false
    }

    if (name.length > 50) {
      this.showError(this.nameErrorTarget, "Nome não pode ter mais de 50 caracteres")
      return false
    }

    this.hideError(this.nameErrorTarget)
    return true
  }

  validateBalance(event) {
    const balance = this.balanceTarget.value

    if (!/^-?\d+([.,]\d{2})?$/.test(balance)) {
      this.showError(this.balanceErrorTarget, "Saldo deve ser um valor monetário válido")
      return false
    }

    this.hideError(this.balanceErrorTarget)
    return true
  }

  validateForm(event) {
    const nameValid = this.validateName()
    const balanceValid = this.validateBalance()

    if (!nameValid || !balanceValid) {
      event.preventDefault()
    }
  }

  showError(target, message) {
    target.textContent = message
    target.classList.remove("hidden")
  }

  hideError(target) {
    target.classList.add("hidden")
  }
}
```

```erb
<!-- View -->
<div data-controller="account-form">
  <%= form_with model: @account, data: { action: "submit->account-form#validateForm" } do |f| %>
    <div>
      <%= f.label :name %>
      <%= f.text_field :name,
          data: {
            account_form_target: "name",
            action: "blur->account-form#validateName"
          } %>
      <span data-account-form-target="nameError" class="hidden text-red-600"></span>
    </div>

    <div>
      <%= f.label :initial_balance %>
      <%= f.text_field :initial_balance,
          data: {
            account_form_target: "balance",
            action: "blur->account-form#validateBalance"
          } %>
      <span data-account-form-target="balanceError" class="hidden text-red-600"></span>
    </div>

    <%= f.submit %>
  <% end %>
</div>
```

```ruby
# Model (server-side validation - always enforced)
class Account < ApplicationRecord
  validates :name, presence: true, length: { maximum: 50 }
  validates :initial_balance_cents, presence: true, numericality: { only_integer: true }
  validates :account_type, presence: true
end
```

### Alternatives Considered
- **No client-side validation**: Poor UX, requires round-trip for every validation error
- **jQuery validation plugin**: Legacy approach, Stimulus is Rails 7 standard
- **React/Vue form validation**: Overkill, breaks Hotwire paradigm, SEO complications

---

## 8. Visual Consistency with Existing Design System

### Decision
Audit existing views (Devise views, User management) to extract color palette, component patterns, and Tailwind utility classes for reuse in account views.

### Rationale
- **Constitution Requirement**: Principle VII mandates visual consistency across all interfaces
- **Design System**: Standardized slate dark theme already defined in constitution
- **Component Reuse**: Buttons, forms, modals, cards should match existing patterns
- **User Trust**: Consistent UI builds user confidence and reduces cognitive load

### Implementation Checklist
1. **Extract existing patterns**:
   - Button styles (primary, secondary, danger)
   - Form input styling (focus states, error states)
   - Card component structure
   - Modal/dialog patterns
   - Loading states and spinners

2. **Color audit**:
   - Background colors: slate-900, slate-800
   - Border colors: slate-700
   - Text colors: white (primary), gray-400 (secondary)
   - Accent colors: cyan-600 (interactive), cyan-400 (hover)
   - Status colors: green-600 (positive), red-600 (negative/errors), yellow-600 (warning)

3. **Typography standards**:
   - Heading sizes: text-2xl, text-xl, text-lg
   - Body text: text-base
   - Small text: text-sm
   - Font weights: font-bold (headings), font-semibold (labels), font-normal (body)

4. **Spacing standards**:
   - Container padding: p-4, p-6
   - Element spacing: space-y-4, space-y-6
   - Form field gaps: gap-4
   - Card margins: m-4

5. **Responsive breakpoints**:
   - Mobile: default (320px+)
   - Tablet: sm: (640px+)
   - Desktop: md: (768px+), lg: (1024px+)

### Pattern Examples from Existing Codebase
```erb
<!-- Primary Button Pattern -->
<button class="bg-cyan-600 hover:bg-cyan-700 text-white font-semibold py-2 px-4 rounded">
  Criar Conta
</button>

<!-- Form Input Pattern -->
<input class="bg-slate-800 border border-slate-700 text-white rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-cyan-600" />

<!-- Card Pattern -->
<div class="bg-slate-800 border border-slate-700 rounded-lg p-6 shadow-lg">
  <!-- content -->
</div>

<!-- Error Message Pattern -->
<p class="text-red-600 text-sm mt-1">Nome não pode ficar em branco</p>
```

### Validation Method
- Use Playwright MCP to capture screenshots of existing views
- Compare new account views side-by-side with existing views
- Verify color consistency with browser DevTools color picker
- Test responsive behavior at 375px (mobile) and 1280px (desktop)

---

## Summary

All research questions have been resolved with concrete decisions and implementation patterns. Key findings:

1. **Rails Enums**: Integer enums for account_type (performance + type safety)
2. **Hotwire**: Turbo Frames + Streams + ActionCable for real-time updates
3. **Money-Rails**: Integer cents columns with automatic BRL formatting
4. **Soft Delete**: `archived_at` timestamp with scopes (reversible + audit-friendly)
5. **Family Creation**: Automatic via User model callback during signup
6. **Balance Calculation**: Dynamic aggregation with optimized eager loading
7. **Validation**: Server-side primary, Stimulus for instant UX feedback
8. **Visual Consistency**: Slate dark theme with pattern reuse from existing views

All patterns follow Rails conventions, satisfy constitution principles, and require no additional gems beyond those already configured in the project.

**Status**: Research complete, ready for Phase 1 (Data Model & Contracts)
