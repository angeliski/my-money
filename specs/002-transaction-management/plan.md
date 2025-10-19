# Implementation Plan: Gestão de Transações

**Branch**: `002-transaction-management` | **Date**: 2025-10-18 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-transaction-management/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

This feature implements the transaction management system for MyMoney, enabling users to register one-time and recurring financial transactions (income and expenses), transfers between accounts, and visualize their transaction history with advanced filtering capabilities. The implementation focuses on registration and visualization features, deferring analytical reporting to a future phase. Key capabilities include automated recurring transaction generation, manual payment marking, account balance calculation, and month-based transaction grouping with daily headers. The system uses Hotwire (Turbo + Stimulus) for real-time UX with modal-based transaction entry requiring careful Turbo Stream handling to avoid jarring user experience.

## Technical Context

**Language/Version**: Ruby 3.3+ / Rails 7.2.2+
**Primary Dependencies**:
- Hotwire (Turbo + Stimulus) for real-time UX
- Tailwind CSS for styling
- money-rails gem for currency handling (BRL, ROUND_HALF_UP)
- Pagy for pagination
- FactoryBot, RSpec, Shoulda Matchers for testing
- SimpleCov for code coverage
- Playwright MCP for browser testing

**Storage**: SQLite3 (development/test), PostgreSQL (production)
**Testing**: RSpec with model/request/system specs, minimum 80% coverage
**Target Platform**: Web application (mobile-first responsive design, 320px+ viewports)
**Project Type**: Web (Rails monolith with Hotwire frontend)
**Performance Goals**:
- Transaction save: <1s
- Filter results: <2s for 10k transactions
- Recurring generation: <2s for 12 months
- Template update: <3s for all future transactions
- Page load: <3s on 3G networks

**Constraints**:
- Modal-based transaction entry using Turbo Frames/Streams (careful UX handling required per user input)
- Monetary values stored as cents (integer columns with _cents postfix)
- Timezone: America/Sao_Paulo for transaction effectuation
- Locale: pt-BR for user-facing text (code in English)
- No API layer (Hotwire only)
- Mobile-first touch-friendly design

**Scale/Scope**:
- Family financial control (up to 10k transactions per account)
- 5 user stories (P1: one-time transactions + transfers + visualization, P2: recurring transactions + template editing, P3: deletion)
- Multiple transaction types: one-time, recurring, transfer
- Advanced filtering: period, type, category, account, status, text search

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Principle I: Rails Convention over Configuration**
- [x] Using Rails generators for all models, migrations, controllers
  - Transaction model via `rails generate model Transaction`
  - TransactionsController via `rails generate controller Transactions`
  - All migrations via `rails generate migration`
- [x] Following RESTful routing patterns
  - Standard CRUD routes: index, show, new, create, edit, update, destroy
  - Nested routes if needed for transfers (e.g., `/transactions/:id/transfer`)
- [x] Leveraging ActiveRecord patterns appropriately
  - Associations: Transaction belongs_to :account, belongs_to :category, belongs_to :user
  - Callbacks for balance calculation (after_save, after_destroy)
  - Scopes for filtering (by_month, by_type, recurring, etc.)

**Principle II: Mobile-First Progressive Enhancement**
- [x] Mobile viewport (320px minimum) designed first
  - Transaction form optimized for 320px+ touch screens
  - Month selector with large touch targets
  - Modal layout responsive from mobile to desktop
- [x] Touch-friendly interfaces
  - Transaction list with swipe actions consideration
  - Large buttons for "Mark as Paid" actions
  - Easy-to-tap category/account selectors
- [x] Progressive enhancement to desktop
  - Desktop adds multi-column layouts for filters
  - Enhanced hover states for desktop users
  - Keyboard shortcuts for power users

**Principle III: Hotwire-Powered Real-time UX**
- [x] Using Turbo for navigation without full page reloads
  - Modal for transaction entry via Turbo Frame
  - Transaction list updates via Turbo Stream after create/edit/delete
  - Month navigation via Turbo Frame replacement
- [x] Stimulus controllers for interactivity
  - TransactionFormController for dynamic form behavior
  - FilterController for client-side filter state
  - ModalController for modal open/close with careful stream handling
- [x] No separate API layer unless justified
  - Pure Hotwire implementation, no JSON API needed

**Principle IV: Testing Standards**
- [x] Comprehensive test coverage planned
  - Model specs: validations, associations, callbacks, scopes, balance calculation
  - Request specs: CRUD actions, filtering, transfers, recurring logic
  - System specs: transaction creation flow, modal interaction, filtering UX
- [x] Minimum 80% code coverage target
  - SimpleCov configured, targeting 80%+ coverage
- [x] Model, request, and system specs planned
  - Transaction model spec with all business logic
  - TransactionsController request spec with all endpoints
  - System spec for end-to-end user flows
- [x] All tests must pass before delivery
  - bin/check enforces test passage

**Principle V: Domain-Driven Design**
- [x] Business logic in models and service objects
  - Transaction model: balance calculation, effectuation logic
  - TransactionService: recurring generation, template updates, transfer creation
  - BalanceCalculator service for complex balance logic
- [x] Thin controllers
  - Controllers delegate to services, only handle HTTP concerns
- [x] Clear domain boundaries
  - Transaction domain separate from Account/Category domains
  - Clear separation: one-time vs recurring vs transfer logic

**Principle VI: User Acceptance Validation via Browser Testing**
- [x] Playwright MCP testing planned for user stories
  - All 5 user stories from spec.md will be validated
  - Browser testing after automated tests pass
- [x] Desktop and mobile viewport validation
  - Test at 375px (mobile) and 1280px+ (desktop)
- [x] User story validation checklist prepared
  - Checklist created from acceptance scenarios in spec.md

**Principle VII: Visual Consistency and Design System**
- [x] Using standardized Tailwind slate dark theme colors
  - slate-900 background, slate-800 secondary, slate-700 borders
  - cyan-600 accents, green-600 for income, red-600 for expenses
- [x] Following existing component patterns
  - Modal pattern consistent with existing application modals
  - Form inputs match existing form styles
  - Buttons follow established button patterns
- [x] Responsive design validation planned
  - Browser testing validates responsive behavior

**Principle VIII: Quality Gates and Delivery Standards**
- [x] bin/check compliance planned (RSpec, Rubocop, Brakeman)
  - All code passes bin/check before delivery
- [x] Maximum test coverage strategy defined
  - Target 80%+ coverage, comprehensive testing of all paths
- [x] Quality gate validation in final phase
  - bin/check run before marking complete

## Project Structure

### Documentation (this feature)

```
specs/002-transaction-management/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (Rails monolith structure)

```
app/
├── models/
│   └── transaction.rb              # Transaction domain model
├── controllers/
│   └── transactions_controller.rb  # RESTful CRUD + filters
├── services/
│   ├── transaction_service.rb      # Recurring generation, template updates
│   ├── transfer_service.rb         # Transfer creation (pair of linked transactions)
│   └── balance_calculator.rb       # Account balance calculation
├── views/
│   └── transactions/
│       ├── index.html.erb          # Transaction list with month selector
│       ├── _form.html.erb          # Transaction form (modal)
│       ├── _transaction.html.erb   # Transaction list item partial
│       └── _filters.html.erb       # Filter panel
├── javascript/
│   └── controllers/
│       ├── transaction_form_controller.js  # Dynamic form behavior
│       ├── filter_controller.js            # Filter state management
│       └── modal_controller.js             # Modal handling with Turbo Stream care
└── helpers/
    └── transactions_helper.rb      # View helpers for transaction display

db/
└── migrate/
    └── [timestamp]_create_transactions.rb  # Transaction schema migration

spec/
├── models/
│   └── transaction_spec.rb         # Model validations, associations, callbacks, scopes
├── requests/
│   └── transactions_spec.rb        # Controller request specs
├── system/
│   └── transactions_spec.rb        # End-to-end browser specs
├── services/
│   ├── transaction_service_spec.rb
│   ├── transfer_service_spec.rb
│   └── balance_calculator_spec.rb
└── factories/
    └── transactions.rb             # FactoryBot factory for Transaction
```

**Structure Decision**: Rails monolith with standard MVC structure. Business logic extracted to service objects in `app/services/`. Hotwire frontend with Stimulus controllers in `app/javascript/controllers/`. No API layer - pure server-rendered Turbo/Stimulus application. Tests organized by type (model/request/system/service specs).

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

No constitution violations detected. All principles are satisfied by the planned implementation.

