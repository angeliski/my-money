# Tasks: Gestão de Transações

**Input**: Design documents from `/specs/002-transaction-management/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Tests are included per constitution requirement (Principle IV - Testing Standards). All tests must pass before delivery.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US1.5, US2, US3, US4, US5)
- Include exact file paths in descriptions

## Path Conventions
- **Rails monolith**: `app/models/`, `app/controllers/`, `app/services/`, `app/views/`, `app/javascript/controllers/`
- **Tests**: `spec/models/`, `spec/requests/`, `spec/system/`, `spec/services/`, `spec/factories/`
- **Database**: `db/migrate/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure for transaction management

- [ ] T001 Verify Account model exists with balance tracking (prerequisite from account management feature)
- [ ] T002 Verify Category model exists with seeded categories including "Transferência" (prerequisite)
- [ ] T003 Verify money-rails gem configured with BRL and ROUND_HALF_UP (check config/initializers/money.rb)
- [ ] T004 [P] Verify Devise user authentication configured and working
- [ ] T005 [P] Verify Hotwire (Turbo + Stimulus) configured in app/javascript/

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core transaction infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Database Schema

- [ ] T006 Generate Transaction model using Rails generator: `rails generate model Transaction transaction_type:string amount_cents:integer currency:string transaction_date:date description:text account:references category:references user:references is_template:boolean frequency:string start_date:date end_date:date parent_transaction:references effectuated_at:datetime linked_transaction:references editor:references edited_at:datetime`
- [ ] T007 Edit migration db/migrate/[timestamp]_create_transactions.rb to add NOT NULL constraints, defaults, and self-referential foreign keys
- [ ] T008 Add performance indexes to migration: transaction_date, transaction_type, category_id, account_id, parent_transaction_id, linked_transaction_id, [is_template, parent_transaction_id]
- [ ] T009 Run migrations: `bin/rails db:migrate && bin/rails db:test:prepare`

### Base Model Configuration

- [ ] T010 Configure Transaction model in app/models/transaction.rb with enums (transaction_type, frequency), monetize :amount_cents, and basic associations
- [ ] T011 Add transaction associations to Account model in app/models/account.rb: `has_many :transactions, dependent: :restrict_with_error`
- [ ] T012 Add transaction associations to Category model in app/models/category.rb: `has_many :transactions, dependent: :restrict_with_error`

### Core Services

- [ ] T013 Create BalanceCalculator service in app/services/balance_calculator.rb with recalculate method (excludes transfers from income/expense totals)
- [ ] T014 Create TransactionService skeleton in app/services/transaction_service.rb (will be extended per user story)
- [ ] T015 Create TransferService skeleton in app/services/transfer_service.rb (will be extended in US1.5)

### Base Factory

- [ ] T016 Create base Transaction factory in spec/factories/transactions.rb with traits for :income, :expense, :template, :transfer

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Cadastro de Transação Pontual (Priority: P1) 🎯 MVP

**Goal**: Enable users to register one-time income/expense transactions with automatic account balance updates

**Independent Test**: Create a one-time expense, verify it appears in transaction list and account balance decreases correctly

### Model Implementation for US1

- [ ] T017 [P] [US1] Add validations to Transaction model: amount_cents > 0, description length 3-500, transaction_date presence, currency = BRL
- [ ] T018 [P] [US1] Add scopes to Transaction model: income, expense, one_time, by_month, in_period, apply_filters
- [ ] T019 [US1] Add callback to Transaction model: after_save/after_destroy :recalculate_account_balance calling BalanceCalculator
- [ ] T020 [US1] Add validation methods to Transaction model: category_not_archived, account_not_archived

### Controller for US1

- [ ] T021 [US1] Generate TransactionsController: `rails generate controller Transactions index new create edit update`
- [ ] T022 [US1] Implement TransactionsController#new action returning Turbo Stream with modal form in app/controllers/transactions_controller.rb
- [ ] T023 [US1] Implement TransactionsController#create action with Turbo Stream response (success: remove modal + prepend transaction + update balance, error: replace modal with errors)
- [ ] T024 [US1] Implement TransactionsController#edit action returning Turbo Stream with modal form
- [ ] T025 [US1] Implement TransactionsController#update action with Turbo Stream response
- [ ] T026 [US1] Add strong parameters and authentication filters to TransactionsController

### Views for US1

- [ ] T027 [P] [US1] Create transaction form partial in app/views/transactions/_form.html.erb with fields: type selector, amount, date, category, account, description
- [ ] T028 [P] [US1] Create transaction modal wrapper in app/views/transactions/_modal_form.html.erb using native dialog element with data-controller="modal"
- [ ] T029 [P] [US1] Create transaction list item partial in app/views/transactions/_transaction.html.erb showing type icon, description, category, account, amount (colored), date

### Stimulus Controllers for US1

- [ ] T030 [P] [US1] Create modal_controller.js in app/javascript/controllers/ handling dialog open/close with animations
- [ ] T031 [P] [US1] Create transaction_form_controller.js in app/javascript/controllers/ handling type toggling and client-side validations

### Routes for US1

- [ ] T032 [US1] Add resources :transactions to config/routes.rb with index, new, create, edit, update actions

### Tests for US1

- [ ] T033 [P] [US1] Write Transaction model spec in spec/models/transaction_spec.rb testing validations, associations, scopes, balance callback
- [ ] T034 [P] [US1] Write TransactionsController request spec in spec/requests/transactions_spec.rb testing create/update one-time transactions with Turbo Stream responses
- [ ] T035 [US1] Write transaction creation system spec in spec/system/transactions_spec.rb testing modal form open, fill, submit, balance update

**Checkpoint**: At this point, User Story 1 should be fully functional - users can create/edit one-time transactions with balance updates

---

## Phase 4: User Story 1.5 - Transferência entre Contas (Priority: P1)

**Goal**: Enable users to transfer money between accounts creating two linked transactions automatically

**Independent Test**: Create a transfer between two accounts, verify both accounts update correctly and transfer doesn't count in income/expense totals

### Service Implementation for US1.5

- [ ] T036 [US1.5] Implement TransferService.create_transfer in app/services/transfer_service.rb creating two linked transactions with category "Transferência"
- [ ] T037 [US1.5] Add transfer linking logic: update both transactions with linked_transaction_id pointing to each other
- [ ] T038 [US1.5] Add transfer validations: from_account != to_account, both accounts exist and not archived

### Controller for US1.5

- [ ] T039 [US1.5] Generate TransfersController: `rails generate controller Transfers new create`
- [ ] T040 [US1.5] Implement TransfersController#new action returning Turbo Stream with transfer modal form in app/controllers/transfers_controller.rb
- [ ] T041 [US1.5] Implement TransfersController#create action calling TransferService and returning Turbo Streams (remove modal + prepend both transactions + update both balances)

### Views for US1.5

- [ ] T042 [P] [US1.5] Create transfer form partial in app/views/transfers/_form.html.erb with fields: from_account, to_account, amount, date, description
- [ ] T043 [US1.5] Update transaction form in app/views/transactions/_form.html.erb to show transfer button opening transfer modal

### Model Extensions for US1.5

- [ ] T044 [P] [US1.5] Add transfer scopes to Transaction model: transfers (joins category "Transferência"), transfer_pair?
- [ ] T045 [P] [US1.5] Add transfer business methods to Transaction model: transfer?, transfer_pair?, validate from != to
- [ ] T046 [US1.5] Update BalanceCalculator in app/services/balance_calculator.rb to include transfers in balance but exclude from income/expense totals

### Routes for US1.5

- [ ] T047 [US1.5] Add resources :transfers to config/routes.rb with only: [:new, :create]

### Tests for US1.5

- [ ] T048 [P] [US1.5] Write TransferService spec in spec/services/transfer_service_spec.rb testing linked transaction creation, balance updates, validations
- [ ] T049 [P] [US1.5] Write TransfersController request spec in spec/requests/transfers_spec.rb testing transfer creation with Turbo Stream responses
- [ ] T050 [US1.5] Write transfer creation system spec in spec/system/transfers_spec.rb testing transfer modal, both account balance updates, income/expense exclusion

**Checkpoint**: At this point, User Stories 1 AND 1.5 should both work - users can create one-time transactions and transfers

---

## Phase 5: User Story 2 - Visualização e Filtragem de Transações (Priority: P1)

**Goal**: Enable users to view transaction list with month-based grouping by day and apply multiple filters

**Independent Test**: View transaction list grouped by day with "Today"/"Yesterday" headers, navigate between months, apply category filter and verify results update without page reload

### Controller Implementation for US2

- [ ] T051 [US2] Implement TransactionsController#index action in app/controllers/transactions_controller.rb with month selection, filtering, and Turbo Frame support
- [ ] T052 [US2] Add filter_params method to TransactionsController permitting: month, type, category_id, account_id, status, search, period_start, period_end, page
- [ ] T053 [US2] Add pagination using Pagy in TransactionsController#index (50 per page)

### Views for US2

- [ ] T054 [P] [US2] Create transactions index view in app/views/transactions/index.html.erb with month selector, filter panel, and transactions list Turbo Frame
- [ ] T055 [P] [US2] Create month selector partial in app/views/transactions/_month_selector.html.erb with previous/next navigation showing "MÊS DE YYYY"
- [ ] T056 [P] [US2] Create filter panel partial in app/views/transactions/_filters.html.erb with form: type, category, account, status, search (data-turbo-frame="transactions_list")
- [ ] T057 [US2] Create transactions list partial in app/views/transactions/_list.html.erb grouping by day with headers (Today, Yesterday, DD DE MÊS DE YYYY • N)
- [ ] T058 [US2] Create totals summary partial in app/views/transactions/_totals.html.erb showing count, income total, expense total for current month

### Helper Methods for US2

- [ ] T059 [P] [US2] Create TransactionsHelper in app/helpers/transactions_helper.rb with methods: format_transaction_amount (colored), format_day_header (Today/Yesterday/full date)
- [ ] T060 [P] [US2] Add grouping helper to TransactionsHelper: group_transactions_by_day returning hash of date => transactions

### Stimulus Controllers for US2

- [ ] T061 [P] [US2] Create filter_controller.js in app/javascript/controllers/ handling auto-submit on filter change with debounce for text search (300ms)
- [ ] T062 [P] [US2] Add month navigation handling to existing controllers to update transactions_list Turbo Frame

### Model Extensions for US2

- [ ] T063 [US2] Enhance apply_filters scope in Transaction model to handle all filter params: type, category_id, account_id, status, search, period_start, period_end

### Tests for US2

- [ ] T064 [P] [US2] Write TransactionsController index request spec in spec/requests/transactions_spec.rb testing filtering, month navigation, Turbo Frame responses
- [ ] T065 [P] [US2] Write TransactionsHelper spec in spec/helpers/transactions_helper_spec.rb testing format methods and grouping
- [ ] T066 [US2] Write transaction filtering system spec in spec/system/transactions_spec.rb testing filter application, month navigation, daily grouping display

**Checkpoint**: At this point, User Stories 1, 1.5, AND 2 should all work - users can create transactions/transfers and view/filter them

---

## Phase 6: User Story 3 - Cadastro de Transação Recorrente (Priority: P2)

**Goal**: Enable users to create recurring transaction templates that automatically generate future transactions up to 12 months ahead

**Independent Test**: Create monthly recurring template, verify 12 future transactions generated, wait for date to arrive and verify transaction becomes effectuated automatically

### Model Extensions for US3

- [ ] T067 [P] [US3] Add template validations to Transaction model: frequency/start_date required if is_template, frequency/start_date absent unless is_template
- [ ] T068 [P] [US3] Add template scopes to Transaction model: templates, generated_from_template, effectuated (timezone-aware), pending (timezone-aware)
- [ ] T069 [US3] Add template callback to Transaction model: after_save :regenerate_future_transactions if saved_change_to_template_attributes?
- [ ] T070 [US3] Add effectuation business methods to Transaction model: effectuated?, manually_effectuated?, pending_by_date?, mark_as_paid!, unmark_as_paid!

### Service Implementation for US3

- [ ] T071 [US3] Implement TransactionService.regenerate_from_template in app/services/transaction_service.rb generating future transactions up to 12 months
- [ ] T072 [US3] Implement TransactionService.calculate_recurrence_dates private method handling frequencies: monthly, bimonthly, quarterly, semiannual, annual
- [ ] T073 [US3] Add logic to regenerate_from_template to delete pending non-manually-effectuated children before regenerating

### Controller Extensions for US3

- [ ] T074 [US3] Update TransactionsController#create to handle is_template param and recurring fields (frequency, start_date, end_date)
- [ ] T075 [US3] Add TransactionsController#mark_as_paid action (POST /transactions/:id/mark_as_paid) calling mark_as_paid! with Turbo Stream response
- [ ] T076 [US3] Add TransactionsController#unmark_as_paid action (DELETE /transactions/:id/mark_as_paid) calling unmark_as_paid! with Turbo Stream response

### View Extensions for US3

- [ ] T077 [US3] Update transaction form in app/views/transactions/_form.html.erb to show recurring fields (checkbox, frequency select, start_date, end_date) conditionally
- [ ] T078 [US3] Update transaction list item in app/views/transactions/_transaction.html.erb to show pending/effectuated status icons and "Mark as Paid" button for pending
- [ ] T079 [US3] Update transaction form controller in app/javascript/controllers/transaction_form_controller.js to toggle recurring fields visibility

### Routes for US3

- [ ] T080 [US3] Add member routes to transactions in config/routes.rb: post :mark_as_paid, delete :mark_as_paid (action: :unmark_as_paid)

### Background Job for US3

- [ ] T081 [US3] Create RegenerateRecurringTransactionsJob in app/jobs/regenerate_recurring_transactions_job.rb running daily to regenerate templates with <12 months future transactions
- [ ] T082 [US3] Configure job scheduling (document in quickstart.md for production setup with whenever/sidekiq)

### Tests for US3

- [ ] T083 [P] [US3] Write TransactionService spec in spec/services/transaction_service_spec.rb testing recurrence generation, date calculations, regeneration logic
- [ ] T084 [P] [US3] Write Transaction model spec for recurring in spec/models/transaction_spec.rb testing template validations, effectuation scopes, mark/unmark methods
- [ ] T085 [P] [US3] Write TransactionsController request spec for recurring in spec/requests/transactions_spec.rb testing template creation, mark_as_paid, unmark actions
- [ ] T086 [US3] Write recurring transaction system spec in spec/system/transactions_spec.rb testing template creation, future transaction generation, mark as paid flow

**Checkpoint**: At this point, User Stories 1-3 should all work - users can create one-time, transfer, recurring transactions and view/filter them

---

## Phase 7: User Story 4 - Edição de Template Recorrente (Priority: P2)

**Goal**: Enable users to edit recurring templates with changes applying only to future pending transactions, not effectuated ones

**Independent Test**: Create recurring template with future transactions, edit template amount, verify only pending future transactions updated, effectuated transactions unchanged

### Model Extensions for US4

- [ ] T087 [US4] Add saved_change_to_template_attributes? private method to Transaction model checking changes to amount_cents, description, category_id, frequency, dates
- [ ] T088 [US4] Enhance regenerate_future_transactions callback to only affect pending non-manually-effectuated children

### Controller Extensions for US4

- [ ] T089 [US4] Ensure TransactionsController#update handles template updates triggering regeneration via callback
- [ ] T090 [US4] Add template edit warnings in TransactionsController showing how many pending transactions will be updated

### View Extensions for US4

- [ ] T091 [US4] Update edit modal in app/views/transactions/_modal_form.html.erb to show warning when editing template: "X pending transactions will be updated"
- [ ] T092 [US4] Add audit trail display to transaction list item showing editor and edit timestamp

### Tests for US4

- [ ] T093 [P] [US4] Write Transaction model spec for template editing in spec/models/transaction_spec.rb testing callback only affects pending transactions
- [ ] T094 [P] [US4] Write TransactionService spec for template updates in spec/services/transaction_service_spec.rb testing regeneration preserves effectuated/manually marked
- [ ] T095 [US4] Write template editing system spec in spec/system/transactions_spec.rb testing edit template, verify pending updated, effectuated unchanged

**Checkpoint**: At this point, User Stories 1-4 should all work - users can edit recurring templates affecting only future pending transactions

---

## Phase 8: User Story 5 - Exclusão de Transações (Priority: P3)

**Goal**: Enable users to delete one-time transactions, templates (removing pending children), and individual generated transactions with confirmation

**Independent Test**: Delete one-time transaction and verify balance updates, delete template and verify only pending children removed, delete one transaction from template and verify template continues

### Controller Implementation for US5

- [ ] T096 [US5] Generate destroy action route (already in resources)
- [ ] T097 [US5] Implement TransactionsController#destroy action in app/controllers/transactions_controller.rb with confirmation and Turbo Stream response
- [ ] T098 [US5] Add deletion logic differentiating: one-time (delete + recalc balance), template (delete + delete pending children), generated (delete single, keep template)
- [ ] T099 [US5] Handle transfer deletion: when deleting one transfer transaction, automatically delete linked transaction too

### View Extensions for US5

- [ ] T100 [US5] Add delete button to transaction list item in app/views/transactions/_transaction.html.erb with data-turbo-method="delete" and data-turbo-confirm
- [ ] T101 [US5] Create confirmation modal or use built-in confirm for deletion

### Model Extensions for US5

- [ ] T102 [US5] Add before_destroy callback to Transaction model: if transfer_pair?, also destroy linked_transaction
- [ ] T103 [US5] Ensure has_many :children association has dependent: :destroy to cascade delete pending children when template deleted

### Tests for US5

- [ ] T104 [P] [US5] Write TransactionsController destroy request spec in spec/requests/transactions_spec.rb testing deletion of one-time, template, generated, transfer transactions
- [ ] T105 [P] [US5] Write Transaction model destroy spec in spec/models/transaction_spec.rb testing cascade deletion, transfer pair deletion, balance recalculation
- [ ] T106 [US5] Write transaction deletion system spec in spec/system/transactions_spec.rb testing delete confirmation, balance update, list update

**Checkpoint**: At this point, all User Stories 1-5 should be complete - full CRUD functionality for all transaction types

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and final quality validation

### Code Quality & Refactoring

- [ ] T107 [P] Run Rubocop auto-fix: `bundle exec rubocop -a` and resolve any remaining violations
- [ ] T108 [P] Run Brakeman security scan: `bundle exec brakeman` and address any warnings
- [ ] T109 Code cleanup: Remove debugging code, unused methods, commented code across all transaction files

### Performance Optimization

- [ ] T110 [P] Verify database indexes exist and are used: analyze query plans for transaction list with filters
- [ ] T111 [P] Add eager loading (includes) to prevent N+1 queries in TransactionsController#index: includes(:account, :category, :user)
- [ ] T112 Optimize balance calculation to only recalculate when amount/account changes, not on every save

### Documentation

- [ ] T113 [P] Add inline documentation to complex methods in TransactionService and BalanceCalculator
- [ ] T114 [P] Update CLAUDE.md with transaction management feature summary and key patterns
- [ ] T115 Add API documentation comments to TransactionsController and TransfersController actions

### Additional Testing

- [ ] T116 [P] Write edge case tests in spec/models/transaction_spec.rb: timezone effectuation, leap year recurrence, max value validation
- [ ] T117 [P] Write BalanceCalculator spec in spec/services/balance_calculator_spec.rb testing transfer exclusion from income/expense, initial balance handling
- [ ] T118 Add performance test for filtering 10k transactions ensuring <2s response time

### Browser Testing (Constitution Principle VI)

- [ ] T119 Manual browser test User Story 1 (one-time transactions) at 375px mobile viewport using Playwright MCP
- [ ] T120 Manual browser test User Story 1 (one-time transactions) at 1280px desktop viewport using Playwright MCP
- [ ] T121 Manual browser test User Story 1.5 (transfers) at both viewports using Playwright MCP
- [ ] T122 Manual browser test User Story 2 (filtering) at both viewports using Playwright MCP
- [ ] T123 Manual browser test User Story 3 (recurring) at both viewports using Playwright MCP
- [ ] T124 Manual browser test User Story 4 (template editing) at both viewports using Playwright MCP
- [ ] T125 Manual browser test User Story 5 (deletion) at both viewports using Playwright MCP
- [ ] T126 Verify modal open/close animations are smooth without jarring UX (addressing user input concern)

### Quality Gate Validation (Constitution Principle VIII)

- [ ] T127 Run complete RSpec test suite: `bundle exec rspec` - verify all tests pass
- [ ] T128 Verify test coverage with SimpleCov: open coverage/index.html and ensure ≥80% coverage across all groups
- [ ] T129 Run full quality gate check: `bin/check` - must pass RSpec, Rubocop, Brakeman with zero failures
- [ ] T130 Verify maximum test coverage achieved: review coverage report and add tests for any uncovered critical paths

### Production Readiness

- [ ] T131 Create database migration rollback plan and test rollback in development
- [ ] T132 Document background job setup for production (RegenerateRecurringTransactionsJob scheduling)
- [ ] T133 Verify production deployment checklist: migrations, seeds ("Transferência" category), background jobs configured

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phases 3-8)**: All depend on Foundational phase completion
  - **US1 (Phase 3)**: Can start after Foundational - No dependencies on other stories
  - **US1.5 (Phase 4)**: Depends on US1 completion (needs basic transaction infrastructure)
  - **US2 (Phase 5)**: Can start after Foundational - Uses US1 transactions but independently testable
  - **US3 (Phase 6)**: Depends on US1 completion (extends basic transactions with templates)
  - **US4 (Phase 7)**: Depends on US3 completion (edits templates created in US3)
  - **US5 (Phase 8)**: Can start after US1 (deletes what US1 creates), but benefits from US1.5, US3 being complete
- **Polish (Phase 9)**: Depends on all user stories being complete

### User Story Dependencies

```
Foundational (Phase 2) → BLOCKS ALL STORIES
    ↓
    ├─→ US1 (Phase 3) ────────┬─→ US1.5 (Phase 4)
    │                         │
    ├─→ US2 (Phase 5) ────────┤
    │   (independent)         │
    │                         ├─→ US3 (Phase 6) ─→ US4 (Phase 7)
    │                         │
    └─→ US5 (Phase 8) ←───────┘
        (needs US1, benefits from all)
```

**Recommended Sequential Order**: Phase 1 → Phase 2 → Phase 3 (US1) → Phase 4 (US1.5) → Phase 5 (US2) → Phase 6 (US3) → Phase 7 (US4) → Phase 8 (US5) → Phase 9 (Polish)

**Parallel Opportunities** (with multiple developers):
- After Phase 2 completes: US1 and US2 can start in parallel
- After US1 completes: US1.5 and US3 can start in parallel
- All [P] marked tasks within a phase can run in parallel

### Within Each User Story

- Models before services
- Services before controllers
- Controllers before views
- Views before Stimulus controllers
- Implementation before tests can run
- Tests must pass before moving to next story

---

## Parallel Example: User Story 1

```bash
# Launch all model validations together:
Task T017: Add validations to Transaction model
Task T018: Add scopes to Transaction model
(These edit different sections of same file - coordinate or do sequentially)

# Launch all view partials together:
Task T027: Create transaction form partial
Task T028: Create transaction modal wrapper
Task T029: Create transaction list item partial

# Launch all Stimulus controllers together:
Task T030: Create modal_controller.js
Task T031: Create transaction_form_controller.js

# Launch all tests together (after implementation complete):
Task T033: Write Transaction model spec
Task T034: Write TransactionsController request spec
Task T035: Write transaction creation system spec
```

---

## Implementation Strategy

### MVP First (User Story 1 + 1.5 + 2 Only - P1 Stories)

1. Complete Phase 1: Setup (verify prerequisites)
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (one-time transactions)
4. Complete Phase 4: User Story 1.5 (transfers)
5. Complete Phase 5: User Story 2 (visualization & filtering)
6. **STOP and VALIDATE**: Test P1 stories together, run bin/check
7. **Deploy MVP**: Users can create/view/filter one-time transactions and transfers

### Incremental Delivery

1. **Foundation**: Setup + Foundational → Database ready
2. **MVP Release** (P1): US1 + US1.5 + US2 → Basic transaction management
3. **Enhanced Release** (P2): Add US3 + US4 → Recurring transactions
4. **Complete Release** (P3): Add US5 → Full CRUD with deletion
5. **Production Release**: Add Polish → Quality gates passed, browser tested

### Parallel Team Strategy

With 2 developers after Foundational phase:
- **Developer A**: US1 → US1.5 → US3 → US4 (transaction creation flow)
- **Developer B**: US2 → US5 (transaction viewing/management flow)
- **Both**: Polish & testing together

With 3 developers:
- **Developer A**: US1 → US1.5 (core transactions + transfers)
- **Developer B**: US2 (visualization & filtering)
- **Developer C**: US3 → US4 → US5 (recurring & deletion)

---

## Task Summary

**Total Tasks**: 133 tasks

**Tasks per Phase**:
- Phase 1 (Setup): 5 tasks
- Phase 2 (Foundational): 11 tasks
- Phase 3 (US1): 19 tasks
- Phase 4 (US1.5): 15 tasks
- Phase 5 (US2): 16 tasks
- Phase 6 (US3): 21 tasks
- Phase 7 (US4): 9 tasks
- Phase 8 (US5): 11 tasks
- Phase 9 (Polish): 26 tasks

**Parallel Tasks**: 57 tasks marked [P] can run in parallel with other tasks

**MVP Scope** (P1 Stories): 51 tasks (Phases 1-5: Setup + Foundational + US1 + US1.5 + US2)

**Estimated Timeline**:
- **MVP (P1)**: ~20-25 hours (single developer)
- **Full Feature (P1+P2+P3)**: ~35-40 hours (single developer)
- **With 2 developers**: ~20-25 hours for full feature

---

## Notes

- [P] tasks = different files or different sections, can run in parallel
- [Story] label maps task to specific user story for traceability
- Each user story should be independently testable at its checkpoint
- Tests are mandatory per constitution (Principle IV)
- Browser testing mandatory per constitution (Principle VI)
- Quality gates mandatory per constitution (Principle VIII)
- All tasks follow checklist format: `- [ ] [ID] [P?] [Story?] Description with file path`
- Commit after completing each user story phase
- Stop at any checkpoint to validate independently before proceeding
- Modal UX carefully handled per user input concern (smooth animations, no jarring transitions)
