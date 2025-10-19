# Routes Contract

**Date**: 2025-10-18
**Feature**: Transaction Management System
**Type**: RESTful Routes Definition

## Overview

This contract defines the expected routes for the transaction management feature, following Rails RESTful conventions with English route paths (as per constitution).

## Routes Table

```ruby
# config/routes.rb
resources :transactions do
  member do
    post :mark_as_paid      # Custom action: mark recurring transaction as paid
    delete :mark_as_paid    # Custom action: unmark (revert to pending)
  end

  collection do
    get :export_csv         # Future: CSV export
    get :export_pdf         # Future: PDF export
  end
end

resources :transfers, only: [:new, :create]  # Specialized controller for transfer creation
```

## Route Details

### Standard RESTful Routes

| HTTP Verb | Path | Controller#Action | Purpose |
|-----------|------|------------------|---------|
| GET | `/transactions` | `transactions#index` | List transactions with filters |
| GET | `/transactions/new` | `transactions#new` | Display new transaction form (modal) |
| POST | `/transactions` | `transactions#create` | Create new transaction |
| GET | `/transactions/:id` | `transactions#show` | Display single transaction details |
| GET | `/transactions/:id/edit` | `transactions#edit` | Display edit transaction form (modal) |
| PATCH/PUT | `/transactions/:id` | `transactions#update` | Update existing transaction |
| DELETE | `/transactions/:id` | `transactions#destroy` | Delete transaction |

### Custom Member Routes

| HTTP Verb | Path | Controller#Action | Purpose |
|-----------|------|------------------|---------|
| POST | `/transactions/:id/mark_as_paid` | `transactions#mark_as_paid` | Manually mark recurring transaction as paid |
| DELETE | `/transactions/:id/mark_as_paid` | `transactions#unmark_as_paid` | Unmark manually paid transaction |

### Collection Routes (Future)

| HTTP Verb | Path | Controller#Action | Purpose |
|-----------|------|------------------|---------|
| GET | `/transactions/export_csv` | `transactions#export_csv` | Export filtered transactions to CSV |
| GET | `/transactions/export_pdf` | `transactions#export_pdf` | Export filtered transactions to PDF |

### Transfer Routes

| HTTP Verb | Path | Controller#Action | Purpose |
|-----------|------|------------------|---------|
| GET | `/transfers/new` | `transfers#new` | Display transfer form (modal) |
| POST | `/transfers` | `transfers#create` | Create transfer (pair of linked transactions) |

## Route Helpers

Rails automatically generates these helper methods:

```ruby
# Path helpers (return path string)
transactions_path                    # => /transactions
new_transaction_path                 # => /transactions/new
transaction_path(@transaction)       # => /transactions/:id
edit_transaction_path(@transaction)  # => /transactions/:id/edit
mark_as_paid_transaction_path(@transaction)  # => /transactions/:id/mark_as_paid

# URL helpers (return full URL string)
transactions_url                     # => http://example.com/transactions
new_transaction_url                  # => http://example.com/transactions/new
transaction_url(@transaction)        # => http://example.com/transactions/:id

# Transfer helpers
new_transfer_path                    # => /transfers/new
transfers_path                       # => /transfers
```

## Query Parameters

### Index Action (`GET /transactions`)

**Filtering Parameters**:
```ruby
{
  month: '2025-01',                   # Format: YYYY-MM
  type: 'income' | 'expense',         # Filter by transaction type
  category_id: '123',                 # Filter by category ID
  account_id: '456',                  # Filter by account ID
  status: 'effectuated' | 'pending',  # Filter by status
  search: 'mercado',                  # Text search in description
  period_start: '2025-01-01',         # Custom period start (overrides month)
  period_end: '2025-01-31',           # Custom period end (overrides month)
  page: '2'                           # Pagination (Pagy)
}
```

**Example URLs**:
```
/transactions                                      # Current month, all transactions
/transactions?month=2024-12                        # December 2024
/transactions?type=expense&category_id=5           # All expenses in category 5
/transactions?account_id=1&status=pending          # Pending in account 1
/transactions?search=supermercado                  # Search for "supermercado"
/transactions?period_start=2025-01-01&period_end=2025-01-15  # Custom range
```

## Request/Response Formats

### Create Transaction (`POST /transactions`)

**Request Headers**:
```
Content-Type: application/x-www-form-urlencoded
Accept: text/vnd.turbo-stream.html
```

**Request Body (One-time Transaction)**:
```ruby
{
  transaction: {
    transaction_type: 'expense',
    amount: '150.00',
    transaction_date: '2025-01-17',
    description: 'Supermercado',
    category_id: '5',
    account_id: '1'
  }
}
```

**Request Body (Recurring Template)**:
```ruby
{
  transaction: {
    transaction_type: 'expense',
    amount: '1500.00',
    transaction_date: '2025-02-05',  # Not used for templates, but required
    description: 'Aluguel mensal',
    category_id: '3',
    account_id: '1',
    is_template: '1',                # Checkbox value
    frequency: 'monthly',
    start_date: '2025-02-05',
    end_date: ''                     # Empty = indefinite
  }
}
```

**Success Response**:
```
Status: 200 OK
Content-Type: text/vnd.turbo-stream.html

<turbo-stream action="remove" target="transaction_modal"></turbo-stream>
<turbo-stream action="prepend" target="transactions_list">...</turbo-stream>
<turbo-stream action="update" target="account_balance">...</turbo-stream>
```

**Error Response**:
```
Status: 422 Unprocessable Entity
Content-Type: text/vnd.turbo-stream.html

<turbo-stream action="replace" target="transaction_modal">
  <!-- Form with errors -->
</turbo-stream>
```

### Create Transfer (`POST /transfers`)

**Request Body**:
```ruby
{
  transfer: {
    from_account_id: '1',
    to_account_id: '2',
    amount: '1000.00',
    transaction_date: '2025-01-17',
    description: 'Aporte mensal',
    recurring: '1',              # Optional
    frequency: 'monthly',        # Required if recurring
    start_date: '2025-01-17',    # Required if recurring
    end_date: ''                 # Optional
  }
}
```

**Success Response**:
```
Status: 200 OK
Content-Type: text/vnd.turbo-stream.html

<turbo-stream action="remove" target="transaction_modal"></turbo-stream>
<turbo-stream action="prepend" target="transactions_list">
  <!-- Both transfer transactions rendered -->
</turbo-stream>
<turbo-stream action="update" target="from_account_balance">...</turbo-stream>
<turbo-stream action="update" target="to_account_balance">...</turbo-stream>
```

### Mark as Paid (`POST /transactions/:id/mark_as_paid`)

**Request**:
```
POST /transactions/123/mark_as_paid
Accept: text/vnd.turbo-stream.html
```

**Success Response**:
```
Status: 200 OK
Content-Type: text/vnd.turbo-stream.html

<turbo-stream action="replace" target="transaction_123">...</turbo-stream>
<turbo-stream action="update" target="account_balance">...</turbo-stream>
```

**Error Response (already effectuated)**:
```
Status: 422 Unprocessable Entity
Content-Type: text/vnd.turbo-stream.html

<turbo-stream action="update" target="flash_messages">
  <template>
    <div class="bg-red-900 text-red-200 p-3 rounded">
      Transação já está efetivada
    </div>
  </template>
</turbo-stream>
```

## Authorization Rules

### Transaction Access
- **Authenticated users only**: All transaction routes require authentication
- **Scoped to user's family**: `Transaction.accessible_by(current_user)` scope applied
- **Creator tracking**: `user_id` set to `current_user.id` on create
- **Editor tracking**: `editor_id` set to `current_user.id` on update

### Route Authorization Matrix

| Action | Permission Required | Notes |
|--------|-------------------|-------|
| `index` | Authenticated | View own family's transactions |
| `new` | Authenticated | Create new transaction |
| `create` | Authenticated | Save new transaction |
| `show` | Authenticated + Ownership | View single transaction |
| `edit` | Authenticated + Ownership | Edit form |
| `update` | Authenticated + Ownership | Save edits |
| `destroy` | Authenticated + Ownership | Delete transaction |
| `mark_as_paid` | Authenticated + Ownership | Mark recurring as paid |
| `unmark_as_paid` | Authenticated + Ownership | Unmark paid |

**Ownership Check**:
```ruby
# In controller
before_action :set_transaction, only: [:show, :edit, :update, :destroy, :mark_as_paid, :unmark_as_paid]

private

def set_transaction
  @transaction = Transaction.accessible_by(current_user).find(params[:id])
rescue ActiveRecord::RecordNotFound
  redirect_to transactions_path, alert: 'Transação não encontrada'
end
```

## Redirect Behavior

### Successful Operations
- **Create**: No redirect, Turbo Stream response
- **Update**: No redirect, Turbo Stream response
- **Destroy**: No redirect, Turbo Stream response
- **Mark/Unmark**: No redirect, Turbo Stream response

### Error Conditions
- **Not Found**: Redirect to `transactions_path` with flash alert
- **Unauthorized**: Redirect to `new_user_session_path` (Devise)
- **Validation Error**: No redirect, Turbo Stream with errors

## Caching Strategy

**No caching for transactions** - Real-time data requires fresh queries
**Cache account balances** - Fragment cache invalidated on transaction create/update/destroy

```erb
<!-- In views -->
<%= cache [@account, 'balance'], expires_in: 5.minutes do %>
  <%= render 'accounts/balance', account: @account %>
<% end %>
```

## Rate Limiting (Future)

**Not implemented in MVP**, but considerations for future:
- Max 60 creates per minute per user
- Max 300 reads per minute per user
- Use Rack::Attack or similar gem

## Notes

- All routes follow Rails RESTful conventions with English paths (per constitution)
- Turbo Frame responses preferred over redirects for better UX
- Query parameters preserved in URL for bookmarkable filtered views
- Transfer routes separated into dedicated controller for clarity
- Custom actions (`mark_as_paid`) follow Rails member route pattern
