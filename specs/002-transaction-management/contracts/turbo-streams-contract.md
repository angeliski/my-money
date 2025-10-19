# Turbo Streams Contract

**Date**: 2025-10-18
**Feature**: Transaction Management System
**Type**: Hotwire Interface Contract

## Overview

This contract defines the expected Turbo Stream responses and DOM structure for transaction management operations. All operations use Turbo Frames and Turbo Streams for partial page updates without full page reloads.

## Turbo Frame Targets

### Primary Frames

| Frame ID | Purpose | Replaces On |
|----------|---------|-------------|
| `transaction_modal` | Modal form for create/edit | Form submit (error only) |
| `transactions_list` | Transaction list with daily grouping | Create, update, delete, filter |
| `account_balance` | Account balance display | Create, update, delete |
| `month_selector` | Month navigation controls | Month change |
| `filter_panel` | Filter form and controls | Filter change |

## Controller Action Contracts

### 1. GET /transactions (Index)

**Purpose**: Display transaction list with filtering

**Query Parameters**:
```ruby
{
  month: '2025-01',           # Optional, defaults to current month
  type: 'income|expense',     # Optional
  category_id: '123',         # Optional
  account_id: '456',          # Optional
  status: 'effectuated|pending', # Optional
  search: 'mercado',          # Optional text search
  period_start: '2025-01-01', # Optional custom period
  period_end: '2025-01-31',   # Optional custom period
  page: '2'                   # Optional pagination
}
```

**Response (HTML)**:
```html
<!-- Full page load -->
<div data-controller="filter">
  <div id="month_selector">
    <!-- Month navigation: ◀ JANEIRO DE 2025 ▶ -->
  </div>

  <div id="filter_panel">
    <form data-turbo-frame="transactions_list" data-action="input->filter#submit">
      <!-- Filter controls -->
    </form>
  </div>

  <turbo-frame id="transactions_list">
    <!-- Transaction list content -->
  </turbo-frame>
</div>
```

**Response (Turbo Frame - filter update)**:
```html
<turbo-frame id="transactions_list">
  <div class="mb-4 flex justify-between">
    <span class="text-sm text-gray-400">15 transações</span>
    <div>
      <span class="text-sm text-green-600">+ R$ 5.000,00</span>
      <span class="text-sm text-red-600">- R$ 1.500,00</span>
    </div>
  </div>

  <!-- Daily groupings -->
  <div class="space-y-4">
    <div>
      <h3 class="text-sm font-semibold text-gray-400 mb-2">
        Today • 3
      </h3>
      <!-- Transaction items -->
    </div>

    <div>
      <h3 class="text-sm font-semibold text-gray-400 mb-2">
        Yesterday • 2
      </h3>
      <!-- Transaction items -->
    </div>

    <div>
      <h3 class="text-sm font-semibold text-gray-400 mb-2">
        15 DE JANEIRO DE 2025 • 5
      </h3>
      <!-- Transaction items -->
    </div>
  </div>
</turbo-frame>
```

---

### 2. GET /transactions/new (New)

**Purpose**: Display transaction creation form in modal

**Response (Turbo Stream)**:
```html
<turbo-stream action="append" target="modals">
  <template>
    <turbo-frame id="transaction_modal">
      <dialog data-controller="modal" class="...">
        <form action="/transactions" method="post" data-turbo-frame="transaction_modal">
          <h2>Nova Transação</h2>

          <!-- Type selector -->
          <div class="flex gap-2">
            <button type="button" data-type="expense" class="...">Despesa</button>
            <button type="button" data-type="income" class="...">Receita</button>
            <button type="button" data-type="transfer" class="...">Transferência</button>
          </div>

          <!-- Form fields -->
          <input type="number" name="transaction[amount]" step="0.01" min="0.01" required />
          <input type="date" name="transaction[transaction_date]" required />
          <select name="transaction[category_id]" required>...</select>
          <select name="transaction[account_id]" required>...</select>
          <textarea name="transaction[description]" required></textarea>

          <!-- Recurring fields (conditional) -->
          <div data-recurring-target="fields" class="hidden">
            <select name="transaction[frequency]">...</select>
            <input type="date" name="transaction[start_date]" />
            <input type="date" name="transaction[end_date]" />
          </div>

          <!-- Transfer fields (conditional) -->
          <div data-transfer-target="fields" class="hidden">
            <select name="transfer[from_account_id]">...</select>
            <select name="transfer[to_account_id]">...</select>
          </div>

          <div class="flex gap-2">
            <button type="submit">Salvar</button>
            <button type="button" data-action="modal#close">Cancelar</button>
          </div>
        </form>
      </dialog>
    </turbo-frame>
  </template>
</turbo-stream>
```

---

### 3. POST /transactions (Create - Success)

**Purpose**: Create transaction and update UI

**Request Payload**:
```ruby
{
  transaction: {
    transaction_type: 'expense',
    amount: '150.00',           # Converted to cents automatically
    transaction_date: '2025-01-17',
    description: 'Supermercado',
    category_id: '5',
    account_id: '1',
    is_template: false,         # Optional
    frequency: 'monthly',       # Required if is_template
    start_date: '2025-01-17',   # Required if is_template
    end_date: nil               # Optional
  }
}
```

**Response (Turbo Stream - Success)**:
```html
<turbo-stream action="remove" target="transaction_modal"></turbo-stream>

<turbo-stream action="prepend" target="transactions_list">
  <template>
    <div id="transaction_123" class="flex items-center justify-between p-4 bg-slate-800 rounded-lg">
      <div class="flex items-center gap-3">
        <div class="text-2xl">🛒</div>
        <div>
          <p class="font-semibold text-white">Supermercado</p>
          <p class="text-sm text-gray-400">Alimentação • Conta Corrente</p>
        </div>
      </div>
      <div class="text-right">
        <p class="font-semibold text-red-600">- R$ 150,00</p>
        <p class="text-xs text-gray-400">17/01/2025</p>
      </div>
    </div>
  </template>
</turbo-stream>

<turbo-stream action="update" target="account_balance">
  <template>
    <span class="text-2xl font-bold text-white">R$ 4.850,00</span>
  </template>
</turbo-stream>
```

---

### 4. POST /transactions (Create - Validation Error)

**Response (Turbo Stream - Error)**:
```html
<turbo-stream action="replace" target="transaction_modal">
  <template>
    <turbo-frame id="transaction_modal">
      <dialog data-controller="modal" class="...">
        <form action="/transactions" method="post" data-turbo-frame="transaction_modal">
          <!-- Same form structure as new, but with errors -->

          <div class="bg-red-900 text-red-200 p-3 rounded mb-4">
            <ul>
              <li>Valor deve ser maior que zero</li>
              <li>Descrição é obrigatória</li>
            </ul>
          </div>

          <!-- Form fields with error highlighting -->
          <input type="number" name="transaction[amount]" class="border-red-600" value="" />
          <textarea name="transaction[description]" class="border-red-600"></textarea>

          <!-- ... rest of form ... -->
        </form>
      </dialog>
    </turbo-frame>
  </template>
</turbo-stream>
```

---

### 5. PATCH /transactions/:id (Update - Success)

**Response (Turbo Stream - Success)**:
```html
<turbo-stream action="remove" target="transaction_modal"></turbo-stream>

<turbo-stream action="replace" target="transaction_123">
  <template>
    <div id="transaction_123" class="flex items-center justify-between p-4 bg-slate-800 rounded-lg">
      <!-- Updated transaction content -->
      <div class="flex items-center gap-3">
        <div class="text-2xl">🛒</div>
        <div>
          <p class="font-semibold text-white">Supermercado - Compra completa</p>
          <p class="text-sm text-gray-400">Alimentação • Conta Corrente</p>
          <p class="text-xs text-gray-500">Editado por João em 17/01/2025</p>
        </div>
      </div>
      <div class="text-right">
        <p class="font-semibold text-red-600">- R$ 200,00</p>
        <p class="text-xs text-gray-400">17/01/2025</p>
      </div>
    </div>
  </template>
</turbo-stream>

<turbo-stream action="update" target="account_balance">
  <template>
    <span class="text-2xl font-bold text-white">R$ 4.800,00</span>
  </template>
</turbo-stream>
```

---

### 6. DELETE /transactions/:id (Destroy)

**Response (Turbo Stream)**:
```html
<turbo-stream action="remove" target="transaction_123"></turbo-stream>

<turbo-stream action="update" target="account_balance">
  <template>
    <span class="text-2xl font-bold text-white">R$ 5.000,00</span>
  </template>
</turbo-stream>

<turbo-stream action="update" target="flash_messages">
  <template>
    <div class="bg-green-900 text-green-200 p-3 rounded">
      Transação excluída com sucesso
    </div>
  </template>
</turbo-stream>
```

---

### 7. POST /transactions/:id/mark_as_paid (Custom Action)

**Purpose**: Manually mark recurring transaction as paid/received before date arrives

**Response (Turbo Stream)**:
```html
<turbo-stream action="replace" target="transaction_456">
  <template>
    <div id="transaction_456" class="flex items-center justify-between p-4 bg-slate-800 rounded-lg">
      <div class="flex items-center gap-3">
        <div class="text-2xl">🏠</div>
        <div>
          <p class="font-semibold text-white">Aluguel</p>
          <p class="text-sm text-gray-400">Moradia • Conta Corrente</p>
          <p class="text-xs text-green-400">✓ Marcado como pago manualmente</p>
        </div>
      </div>
      <div class="text-right">
        <p class="font-semibold text-red-600">- R$ 1.500,00</p>
        <p class="text-xs text-gray-400">05/02/2025</p>
      </div>
    </div>
  </template>
</turbo-stream>

<turbo-stream action="update" target="account_balance">
  <template>
    <span class="text-2xl font-bold text-white">R$ 3.500,00</span>
  </template>
</turbo-stream>
```

---

### 8. DELETE /transactions/:id/mark_as_paid (Unmark)

**Purpose**: Unmark manually paid transaction (reverting to pending)

**Response (Turbo Stream)**:
```html
<turbo-stream action="replace" target="transaction_456">
  <template>
    <div id="transaction_456" class="flex items-center justify-between p-4 bg-slate-800 rounded-lg opacity-60">
      <div class="flex items-center gap-3">
        <div class="text-2xl">🏠</div>
        <div>
          <p class="font-semibold text-white">Aluguel</p>
          <p class="text-sm text-gray-400">Moradia • Conta Corrente</p>
          <p class="text-xs text-yellow-400">⏳ Pendente</p>
        </div>
      </div>
      <div class="text-right">
        <p class="font-semibold text-red-600">- R$ 1.500,00</p>
        <p class="text-xs text-gray-400">05/02/2025</p>
      </div>
    </div>
  </template>
</turbo-stream>

<turbo-stream action="update" target="account_balance">
  <template>
    <span class="text-2xl font-bold text-white">R$ 5.000,00</span>
  </template>
</turbo-stream>
```

## Stimulus Controller Contracts

### modal_controller.js

**Data Attributes**:
- `data-controller="modal"`: Attached to `<dialog>` element
- `data-action="modal#close"`: Attached to cancel/close buttons

**Methods**:
```javascript
connect()     // Opens dialog, sets up event listeners
disconnect()  // Cleanup
close()       // Closes dialog with fade-out animation
```

---

### filter_controller.js

**Data Attributes**:
- `data-controller="filter"`: Attached to wrapper div
- `data-filter-target="form"`: Attached to filter form
- `data-action="input->filter#submit"`: Attached to filter inputs (auto-submit)
- `data-action="input->filter#debounceSubmit"`: Attached to text search input (debounced)

**Methods**:
```javascript
connect()           // Initialize debounce timer
submit()            // Immediately submit form
debounceSubmit()    // Submit after 300ms delay
```

---

### transaction_form_controller.js

**Data Attributes**:
- `data-controller="transaction-form"`: Attached to form element
- `data-transaction-form-target="recurringFields"`: Recurring section
- `data-transaction-form-target="transferFields"`: Transfer section
- `data-action="change->transaction-form#toggleType"`: Type selector buttons

**Methods**:
```javascript
connect()           // Initialize form state
toggleType(event)   // Show/hide recurring or transfer fields based on type
validateAmount()    // Client-side validation for amount > 0
```

## Error Handling Patterns

### Validation Errors
- **Response**: Turbo Stream replacing modal frame with errors highlighted
- **Status Code**: 422 Unprocessable Entity
- **Modal Behavior**: Stays open, shows errors inline

### Server Errors
- **Response**: Turbo Stream updating flash messages area
- **Status Code**: 500 Internal Server Error
- **Modal Behavior**: Closes, shows error message in main page

### Not Found
- **Response**: Redirect to transactions index with flash error
- **Status Code**: 404 Not Found

### Unauthorized
- **Response**: Redirect to sign-in page
- **Status Code**: 401 Unauthorized

## Performance Expectations

| Operation | Expected Response Time | Turbo Streams Count |
|-----------|----------------------|---------------------|
| Create transaction | <1s | 3 (remove modal, prepend item, update balance) |
| Update transaction | <1s | 3 (remove modal, replace item, update balance) |
| Delete transaction | <500ms | 3 (remove item, update balance, flash message) |
| Filter (10k records) | <2s | 1 (replace list frame) |
| Month navigation | <1s | 1 (replace list frame) |
| Mark as paid | <500ms | 2 (replace item, update balance) |

## Accessibility Requirements

- All modals use native `<dialog>` element
- Turbo Frame navigation updates `aria-live` regions
- Loading states announced to screen readers
- Keyboard navigation fully supported (Esc to close modal, Tab navigation)
- Focus management: modal opens → focus on first field, modal closes → focus returns to trigger button

## Mobile Considerations

- Touch targets minimum 44x44px
- Swipe gestures NOT used (conflicts with native browser gestures)
- Modal overlays full screen on mobile (<768px)
- Filter panel collapsible on mobile with toggle button
- Month selector uses native date picker on mobile
