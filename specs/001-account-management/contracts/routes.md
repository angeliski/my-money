# Routes Contract: Account Management

**Feature**: 001-account-management
**Date**: 2025-10-18
**Type**: Rails RESTful Routes + Custom Actions

## Overview

This document defines the HTTP routes, request/response contracts, and Turbo Stream interactions for the Account Management feature. The application uses Rails conventions with Hotwire (Turbo + Stimulus) for a server-rendered, SPA-like experience.

---

## Route Table

### Standard RESTful Routes

| HTTP Method | Path                  | Controller#Action    | Purpose                           | Turbo Frame Support |
|-------------|-----------------------|---------------------|-----------------------------------|---------------------|
| GET         | /accounts             | accounts#index      | List all active accounts          | Yes                 |
| GET         | /accounts/new         | accounts#new        | New account form                  | Yes                 |
| POST        | /accounts             | accounts#create     | Create account                    | Yes (Turbo Stream) |
| GET         | /accounts/:id         | accounts#show       | Show account details              | Yes                 |
| GET         | /accounts/:id/edit    | accounts#edit       | Edit account form                 | Yes                 |
| PATCH/PUT   | /accounts/:id         | accounts#update     | Update account                    | Yes (Turbo Stream) |
| DELETE      | /accounts/:id/archive | accounts#archive    | Archive account (soft delete)     | Yes (Turbo Stream) |
| PATCH       | /accounts/:id/unarchive | accounts#unarchive | Unarchive account                 | Yes (Turbo Stream) |

### Routes Configuration

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :accounts, except: [:destroy] do
    member do
      delete :archive      # Soft delete
      patch :unarchive     # Restore archived account
    end
  end
end
```

### Generated Route Helpers

```ruby
accounts_path                # /accounts
new_account_path             # /accounts/new
account_path(account)        # /accounts/:id
edit_account_path(account)   # /accounts/:id/edit
archive_account_path(account) # /accounts/:id/archive
unarchive_account_path(account) # /accounts/:id/unarchive
```

---

## Request/Response Contracts

### 1. Index - List Accounts

#### Request

**HTTP Method**: `GET`
**Path**: `/accounts`
**Query Parameters**:
- `show_archived` (optional, boolean): Include archived accounts in separate section

**Headers**:
```
Accept: text/html
```

**Authentication**: Required (Devise current_user)

#### Response (Success)

**Status**: `200 OK`

**Content-Type**: `text/html; charset=utf-8`

**Body Structure**:
```html
<div id="accounts-page">
  <!-- Total Net Worth Summary -->
  <div id="accounts-total" class="...">
    <h2>Patrimônio Total</h2>
    <span class="text-2xl">R$ 16.500,00</span>
  </div>

  <!-- Active Accounts List -->
  <div id="accounts-list" class="...">
    <!-- Turbo Stream target for real-time updates -->
    <%= turbo_stream_from "family_#{current_user.family_id}_accounts" %>

    <!-- Account cards -->
    <div id="account_123" class="account-card">
      <span class="icon">🏦</span>
      <h3>Nubank</h3>
      <p class="balance positive">R$ 1.500,00</p>
      <div class="actions">
        <a href="/accounts/123/edit">Editar</a>
        <a href="/accounts/123/archive" data-turbo-method="delete">Arquivar</a>
      </div>
    </div>
    <!-- More accounts... -->
  </div>

  <!-- Archived Accounts (if show_archived=true) -->
  <div id="archived-accounts-list" class="...">
    <!-- Archived account cards (read-only) -->
  </div>

  <!-- Empty State (if no accounts) -->
  <div id="empty-state" class="...">
    <p>Você ainda não possui contas cadastradas</p>
    <a href="/accounts/new" class="btn-primary">Criar Primeira Conta</a>
  </div>
</div>
```

**Turbo Frame Support**: Entire page can be loaded in frame `"accounts-page"`

---

### 2. New - Account Creation Form

#### Request

**HTTP Method**: `GET`
**Path**: `/accounts/new`

**Headers**:
```
Accept: text/html
Turbo-Frame: account-form (optional, for modal)
```

**Authentication**: Required

#### Response (Success)

**Status**: `200 OK`

**Content-Type**: `text/html; charset=utf-8`

**Body Structure**:
```html
<turbo-frame id="account-form">
  <form action="/accounts" method="post" data-controller="account-form">
    <%= csrf_token %>

    <!-- Account Name -->
    <div class="field">
      <label for="account_name">Nome da Conta</label>
      <input type="text" name="account[name]" id="account_name" maxlength="50"
             data-account-form-target="name"
             data-action="blur->account-form#validateName"
             required />
      <span class="error" data-account-form-target="nameError"></span>
    </div>

    <!-- Account Type -->
    <div class="field">
      <label for="account_account_type">Tipo</label>
      <select name="account[account_type]" id="account_account_type" required>
        <option value="">Selecione...</option>
        <option value="checking">🏦 Corrente</option>
        <option value="investment">📈 Investimentos</option>
      </select>
    </div>

    <!-- Initial Balance -->
    <div class="field">
      <label for="account_initial_balance">Saldo Inicial</label>
      <input type="text" name="account[initial_balance]" id="account_initial_balance"
             placeholder="0,00"
             data-account-form-target="balance"
             data-action="blur->account-form#validateBalance"
             required />
      <span class="error" data-account-form-target="balanceError"></span>
      <small>Pode ser positivo, zero ou negativo</small>
    </div>

    <!-- Submit -->
    <button type="submit" class="btn-primary">Criar Conta</button>
    <a href="/accounts" class="btn-secondary">Cancelar</a>
  </form>
</turbo-frame>
```

---

### 3. Create - Create New Account

#### Request

**HTTP Method**: `POST`
**Path**: `/accounts`

**Headers**:
```
Accept: text/vnd.turbo-stream.html, text/html
Content-Type: application/x-www-form-urlencoded
```

**Body Parameters**:
```ruby
{
  account: {
    name: string,                    # Required, max 50 characters
    account_type: enum,              # Required, "checking" or "investment"
    initial_balance: string          # Required, monetary format (e.g., "1500,00" or "-500,00")
  }
}
```

**Example**:
```
account[name]=Nubank
account[account_type]=checking
account[initial_balance]=1500,00
```

**Authentication**: Required

#### Response (Success - Turbo Stream)

**Status**: `200 OK`

**Content-Type**: `text/vnd.turbo-stream.html; charset=utf-8`

**Body**:
```html
<turbo-stream action="prepend" target="accounts-list">
  <template>
    <div id="account_123" class="account-card">
      <span class="icon">🏦</span>
      <h3>Nubank</h3>
      <p class="balance positive">R$ 1.500,00</p>
      <div class="actions">
        <a href="/accounts/123/edit">Editar</a>
        <a href="/accounts/123/archive" data-turbo-method="delete">Arquivar</a>
      </div>
    </div>
  </template>
</turbo-stream>

<turbo-stream action="replace" target="accounts-total">
  <template>
    <div id="accounts-total" class="...">
      <h2>Patrimônio Total</h2>
      <span class="text-2xl">R$ 17.000,00</span>
    </div>
  </template>
</turbo-stream>

<turbo-stream action="remove" target="empty-state">
  <template></template>
</turbo-stream>

<turbo-stream action="replace" target="account-form">
  <template>
    <div class="notice">Conta criada com sucesso!</div>
  </template>
</turbo-stream>
```

**Broadcast**: ActionCable broadcast to all family members via channel:
```ruby
Turbo::StreamsChannel.broadcast_prepend_to(
  "family_#{family.id}_accounts",
  target: "accounts-list",
  partial: "accounts/account",
  locals: { account: @account }
)
```

#### Response (Validation Error)

**Status**: `422 Unprocessable Entity`

**Content-Type**: `text/vnd.turbo-stream.html; charset=utf-8`

**Body**:
```html
<turbo-stream action="replace" target="account-form">
  <template>
    <!-- Re-render form with error messages -->
    <form action="/accounts" method="post" data-controller="account-form">
      <!-- Fields with errors highlighted -->
      <div class="field field-with-errors">
        <label for="account_name">Nome da Conta</label>
        <input type="text" name="account[name]" id="account_name" value="" class="error" />
        <span class="error">não pode ficar em branco</span>
      </div>
      <!-- ... rest of form ... -->
    </form>
  </template>
</turbo-stream>
```

**Validation Errors**:
```json
{
  "name": ["não pode ficar em branco", "deve ter no máximo 50 caracteres"],
  "account_type": ["não pode ficar em branco"],
  "initial_balance": ["não é um número válido"]
}
```

---

### 4. Show - Account Details

#### Request

**HTTP Method**: `GET`
**Path**: `/accounts/:id`

**Headers**:
```
Accept: text/html
```

**Authentication**: Required (must own account via family)

#### Response (Success)

**Status**: `200 OK`

**Content-Type**: `text/html; charset=utf-8`

**Body Structure**:
```html
<div id="account_123" class="account-details">
  <!-- Account Header -->
  <div class="header">
    <span class="icon">🏦</span>
    <h1>Nubank</h1>
    <span class="badge">Corrente</span>
  </div>

  <!-- Balance Summary -->
  <div class="balance-summary">
    <div class="current-balance">
      <label>Saldo Atual</label>
      <span class="balance positive">R$ 1.500,00</span>
    </div>
    <div class="initial-balance">
      <label>Saldo Inicial</label>
      <span>R$ 1.500,00</span>
    </div>
  </div>

  <!-- Actions -->
  <div class="actions">
    <a href="/accounts/123/edit" class="btn-primary">Editar</a>
    <a href="/accounts/123/archive" data-turbo-method="delete" data-turbo-confirm="Tem certeza?" class="btn-danger">Arquivar</a>
  </div>

  <!-- Transactions List (Future Phase) -->
  <div id="transactions-list">
    <h2>Transações</h2>
    <p>Nenhuma transação registrada ainda</p>
  </div>
</div>
```

#### Response (Not Found)

**Status**: `404 Not Found`

**Body**: Standard Rails 404 error page

#### Response (Unauthorized)

**Status**: `403 Forbidden`

**Body**: Error page indicating account belongs to another family

---

### 5. Edit - Account Edit Form

#### Request

**HTTP Method**: `GET`
**Path**: `/accounts/:id/edit`

**Headers**:
```
Accept: text/html
Turbo-Frame: account-form (optional, for modal)
```

**Authentication**: Required (must own account via family)

#### Response (Success)

**Status**: `200 OK`

**Content-Type**: `text/html; charset=utf-8`

**Body Structure**:
```html
<turbo-frame id="account-form">
  <form action="/accounts/123" method="post" data-controller="account-form">
    <%= csrf_token %>
    <input type="hidden" name="_method" value="patch" />

    <!-- Account Name (editable) -->
    <div class="field">
      <label for="account_name">Nome da Conta</label>
      <input type="text" name="account[name]" id="account_name" value="Nubank" maxlength="50"
             data-account-form-target="name"
             data-action="blur->account-form#validateName"
             required />
      <span class="error" data-account-form-target="nameError"></span>
    </div>

    <!-- Account Type (read-only, immutable) -->
    <div class="field">
      <label for="account_account_type">Tipo</label>
      <select name="account[account_type]" id="account_account_type" disabled>
        <option value="checking" selected>🏦 Corrente</option>
        <option value="investment">📈 Investimentos</option>
      </select>
      <small class="text-gray-400">Tipo não pode ser alterado após criação</small>
    </div>

    <!-- Initial Balance (editable) -->
    <div class="field">
      <label for="account_initial_balance">Saldo Inicial</label>
      <input type="text" name="account[initial_balance]" id="account_initial_balance"
             value="1500,00"
             data-account-form-target="balance"
             data-action="blur->account-form#validateBalance"
             required />
      <span class="error" data-account-form-target="balanceError"></span>
      <small class="text-yellow-600">Alterar saldo inicial recalcula saldo atual</small>
    </div>

    <!-- Submit -->
    <button type="submit" class="btn-primary">Salvar Alterações</button>
    <a href="/accounts/123" class="btn-secondary">Cancelar</a>
  </form>
</turbo-frame>
```

---

### 6. Update - Update Account

#### Request

**HTTP Method**: `PATCH` or `PUT`
**Path**: `/accounts/:id`

**Headers**:
```
Accept: text/vnd.turbo-stream.html, text/html
Content-Type: application/x-www-form-urlencoded
```

**Body Parameters**:
```ruby
{
  account: {
    name: string,                    # Optional, max 50 characters
    initial_balance: string          # Optional, monetary format
    # account_type NOT allowed (immutable)
  }
}
```

**Example**:
```
_method=patch
account[name]=Nubank Atualizado
account[initial_balance]=2000,00
```

**Authentication**: Required (must own account via family)

#### Response (Success - Turbo Stream)

**Status**: `200 OK`

**Content-Type**: `text/vnd.turbo-stream.html; charset=utf-8`

**Body**:
```html
<turbo-stream action="replace" target="account_123">
  <template>
    <div id="account_123" class="account-card">
      <span class="icon">🏦</span>
      <h3>Nubank Atualizado</h3>
      <p class="balance positive">R$ 2.000,00</p>
      <div class="actions">
        <a href="/accounts/123/edit">Editar</a>
        <a href="/accounts/123/archive" data-turbo-method="delete">Arquivar</a>
      </div>
    </div>
  </template>
</turbo-stream>

<turbo-stream action="replace" target="accounts-total">
  <template>
    <div id="accounts-total" class="...">
      <h2>Patrimônio Total</h2>
      <span class="text-2xl">R$ 17.500,00</span>
    </div>
  </template>
</turbo-stream>

<turbo-stream action="replace" target="account-form">
  <template>
    <div class="notice">Conta atualizada com sucesso!</div>
  </template>
</turbo-stream>
```

**Broadcast**: ActionCable broadcast to all family members

#### Response (Validation Error)

Same as Create validation error (422 Unprocessable Entity)

---

### 7. Archive - Soft Delete Account

#### Request

**HTTP Method**: `DELETE`
**Path**: `/accounts/:id/archive`

**Headers**:
```
Accept: text/vnd.turbo-stream.html, text/html
```

**Authentication**: Required (must own account via family)

**Confirmation**: JavaScript confirm dialog via `data-turbo-confirm` attribute

#### Response (Success - Turbo Stream)

**Status**: `200 OK`

**Content-Type**: `text/vnd.turbo-stream.html; charset=utf-8`

**Body**:
```html
<turbo-stream action="remove" target="account_123">
  <template></template>
</turbo-stream>

<turbo-stream action="replace" target="accounts-total">
  <template>
    <div id="accounts-total" class="...">
      <h2>Patrimônio Total</h2>
      <span class="text-2xl">R$ 15.500,00</span>
    </div>
  </template>
</turbo-stream>

<turbo-stream action="append" target="flash-messages">
  <template>
    <div class="notice">Conta arquivada com sucesso. Histórico preservado.</div>
  </template>
</turbo-stream>
```

**Broadcast**: ActionCable broadcast to all family members

#### Response (Error - Has Transactions)

**Status**: `422 Unprocessable Entity`

**Body**:
```html
<turbo-stream action="append" target="flash-messages">
  <template>
    <div class="alert">Não é possível arquivar conta com transações. Use a ação de arquivamento que preserva histórico.</div>
  </template>
</turbo-stream>
```

---

### 8. Unarchive - Restore Archived Account

#### Request

**HTTP Method**: `PATCH`
**Path**: `/accounts/:id/unarchive`

**Headers**:
```
Accept: text/vnd.turbo-stream.html, text/html
```

**Authentication**: Required (must own account via family)

#### Response (Success - Turbo Stream)

**Status**: `200 OK`

**Content-Type**: `text/vnd.turbo-stream.html; charset=utf-8`

**Body**:
```html
<turbo-stream action="remove" target="account_123">
  <template></template>
</turbo-stream>

<turbo-stream action="prepend" target="accounts-list">
  <template>
    <div id="account_123" class="account-card">
      <span class="icon">🏦</span>
      <h3>Conta Antiga</h3>
      <p class="balance positive">R$ 0,00</p>
      <div class="actions">
        <a href="/accounts/123/edit">Editar</a>
        <a href="/accounts/123/archive" data-turbo-method="delete">Arquivar</a>
      </div>
    </div>
  </template>
</turbo-stream>

<turbo-stream action="replace" target="accounts-total">
  <template>
    <div id="accounts-total" class="...">
      <h2>Patrimônio Total</h2>
      <span class="text-2xl">R$ 15.500,00</span>
    </div>
  </template>
</turbo-stream>
```

**Broadcast**: ActionCable broadcast to all family members

---

## Turbo Streams Channel Contract

### Channel Subscription

**Channel**: `Turbo::StreamsChannel`

**Stream Name**: `family_{family_id}_accounts`

**Subscription Code**:
```erb
<!-- In view -->
<%= turbo_stream_from "family_#{current_user.family_id}_accounts" %>
```

**Generated HTML**:
```html
<turbo-cable-stream-source channel="Turbo::StreamsChannel" signed-stream-name="encrypted_string_here"></turbo-cable-stream-source>
```

### Broadcast Events

#### Account Created
```ruby
Turbo::StreamsChannel.broadcast_prepend_to(
  "family_#{family.id}_accounts",
  target: "accounts-list",
  partial: "accounts/account",
  locals: { account: @account }
)
```

#### Account Updated
```ruby
Turbo::StreamsChannel.broadcast_replace_to(
  "family_#{family.id}_accounts",
  target: "account_#{@account.id}",
  partial: "accounts/account",
  locals: { account: @account }
)
```

#### Account Archived
```ruby
Turbo::StreamsChannel.broadcast_remove_to(
  "family_#{family.id}_accounts",
  target: "account_#{@account.id}"
)
```

#### Total Updated
```ruby
Turbo::StreamsChannel.broadcast_replace_to(
  "family_#{family.id}_accounts",
  target: "accounts-total",
  partial: "accounts/total",
  locals: { total: calculate_total }
)
```

---

## Error Responses

### 401 Unauthorized
**Scenario**: User not authenticated

**Response**: Redirect to `/users/sign_in` (Devise)

### 403 Forbidden
**Scenario**: User trying to access account from different family

**Status**: `403 Forbidden`

**Body**:
```html
<div class="error-page">
  <h1>Acesso Negado</h1>
  <p>Você não tem permissão para acessar esta conta.</p>
  <a href="/accounts">Voltar para Minhas Contas</a>
</div>
```

### 404 Not Found
**Scenario**: Account ID doesn't exist

**Status**: `404 Not Found`

**Body**: Standard Rails 404 page

### 422 Unprocessable Entity
**Scenario**: Validation errors

**Content-Type**: `text/vnd.turbo-stream.html` or `text/html`

**Body**: Re-rendered form with error messages (see Create/Update responses above)

### 500 Internal Server Error
**Scenario**: Unexpected server error

**Status**: `500 Internal Server Error`

**Body**: Standard Rails 500 error page

---

## Security Considerations

### CSRF Protection
All POST/PATCH/DELETE requests require valid CSRF token:
```html
<input type="hidden" name="authenticity_token" value="..." />
```

### Authorization
- All routes require authentication (Devise `before_action :authenticate_user!`)
- Account access scoped by family: `current_user.family.accounts.find(params[:id])`
- Prevents cross-family data access

### Parameter Filtering
```ruby
# Controller
def account_params
  params.require(:account).permit(:name, :account_type, :initial_balance)
end
```

**Prohibited Parameters**:
- `id` (cannot change primary key)
- `family_id` (cannot move account between families)
- `archived_at` (must use archive/unarchive actions)
- `created_at`, `updated_at` (managed by Rails)

### SQL Injection Prevention
- All queries use ActiveRecord parameterization
- No raw SQL with user input

### XSS Prevention
- All user input escaped via ERB `<%= %>` syntax
- HTML sanitization on text fields

---

## Performance Optimizations

### Caching Strategy

#### Fragment Caching
```erb
<% cache(cache_key_for_accounts) do %>
  <%= render @accounts %>
<% end %>
```

**Cache Key**: `accounts/family-#{family.id}-#{family.updated_at}-#{accounts.cache_key_with_version}`

**Invalidation**: Automatic on account create/update/archive

#### HTTP Caching
```ruby
# Controller
def index
  @accounts = current_user.family.accounts.active
  fresh_when(@accounts)
end
```

**Headers**:
```
ETag: "abc123..."
Last-Modified: Tue, 18 Oct 2025 12:00:00 GMT
```

### Query Optimization

#### N+1 Prevention
```ruby
# Bad (N+1)
@accounts.each { |account| account.current_balance }

# Good (eager loading)
@accounts = current_user.family.accounts.active.with_balance_data
```

#### Pagination (Future)
```ruby
@accounts = current_user.family.accounts.active.page(params[:page])
```

---

## Testing Checklist

### Request Specs
- [ ] GET /accounts - returns 200 with account list
- [ ] GET /accounts - shows empty state when no accounts
- [ ] GET /accounts?show_archived=true - includes archived accounts
- [ ] GET /accounts/new - returns 200 with form
- [ ] POST /accounts - creates account with valid params
- [ ] POST /accounts - returns 422 with invalid params
- [ ] GET /accounts/:id - returns 200 for owned account
- [ ] GET /accounts/:id - returns 403 for other family's account
- [ ] GET /accounts/:id/edit - returns 200 with edit form
- [ ] PATCH /accounts/:id - updates account with valid params
- [ ] PATCH /accounts/:id - returns 422 with invalid params
- [ ] DELETE /accounts/:id/archive - archives account
- [ ] PATCH /accounts/:id/unarchive - unarchives account

### System Specs (Browser Testing)
- [ ] User can create first account
- [ ] User can view account list with balances
- [ ] User can edit account name and initial balance
- [ ] User can archive account
- [ ] User can unarchive account
- [ ] Real-time updates appear for family members
- [ ] Mobile viewport (375px) displays correctly
- [ ] Desktop viewport (1280px) displays correctly

---

## Summary

The routes contract defines:
- ✓ RESTful routes following Rails conventions
- ✓ Turbo Stream responses for real-time updates
- ✓ ActionCable broadcasts for family-wide synchronization
- ✓ Comprehensive error handling
- ✓ Security measures (CSRF, authorization, XSS prevention)
- ✓ Performance optimizations (caching, eager loading)

All contracts follow Rails 7.2 and Hotwire best practices.

**Status**: Routes contract complete
