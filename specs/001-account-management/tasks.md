# Tasks: Account Management (Gestão de Contas Financeiras)

**Input**: Design documents from `/home/angeliski/workspace/my-money/specs/001-account-management/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/routes.md

**Tests**: Tests are included in this feature (comprehensive RSpec test coverage required per Constitution Principle IV)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4, US5)
- Include exact file paths in descriptions

## Path Conventions (Rails Monolith)
- **Models**: `app/models/`
- **Controllers**: `app/controllers/`
- **Views**: `app/views/accounts/`
- **Services**: `app/services/`
- **JavaScript**: `app/javascript/controllers/`
- **Specs**: `spec/models/`, `spec/requests/`, `spec/system/`, `spec/factories/`
- **Migrations**: `db/migrate/`
- **I18n**: `config/locales/pt-BR/`
- **Routes**: `config/routes.rb`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Database schema setup and foundational models required by all user stories

- [ ] T001 Generate Family model migration using `bundle exec rails generate model Family`
- [ ] T002 Generate Account model migration using `bundle exec rails generate model Account name:string account_type:integer initial_balance_cents:integer icon:string color:string archived_at:datetime family:references`
- [ ] T003 Generate AddFamilyToUsers migration using `bundle exec rails generate migration AddFamilyToUsers family:references`
- [ ] T004 Run migrations with `bundle exec rails db:migrate && bundle exec rails db:test:prepare`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core models, associations, and test infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T005 [P] Implement Family model with associations in app/models/family.rb
- [ ] T006 [P] Extend User model with family association and auto-creation callback in app/models/user.rb
- [ ] T007 [P] Implement Account model with validations, enums, scopes, and callbacks in app/models/account.rb
- [ ] T008 [P] Create Family factory in spec/factories/families.rb
- [ ] T009 [P] Create Account factory with traits in spec/factories/accounts.rb
- [ ] T010 [P] Write Family model specs in spec/models/family_spec.rb
- [ ] T011 [P] Write Account model specs (validations, scopes, methods) in spec/models/account_spec.rb
- [ ] T012 [P] Write User model extension specs in spec/models/user_spec.rb
- [ ] T013 Run model specs with `bundle exec rspec spec/models/` to verify foundation

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Criar primeira conta financeira (Priority: P1) 🎯 MVP

**Goal**: Enable users to create their first financial account (checking or investment) with automatic family association

**Independent Test**: Create an account, verify it appears in the listing with correct initial balance, icon, and color. Account is ready to receive transactions.

**Acceptance Scenarios**:
1. User sees empty state with "create account" option when no accounts exist
2. User creates checking account "Nubank" with R$ 1.500,00 initial balance → appears with 🏦 blue icon
3. User creates investment account → appears with 📈 green icon
4. Initial balance not counted as income in reports

### Implementation for User Story 1

- [ ] T014 [US1] Configure routes for accounts resource in config/routes.rb (resources :accounts, except: [:destroy] with archive/unarchive member actions)
- [ ] T015 [P] [US1] Generate AccountsController with `bundle exec rails generate controller Accounts index new create show edit update`
- [ ] T016 [P] [US1] Implement AccountsHelper with total_net_worth, format_balance, balance_class methods in app/helpers/accounts_helper.rb
- [ ] T017 [US1] Implement AccountsController#new action in app/controllers/accounts_controller.rb
- [ ] T018 [US1] Implement AccountsController#create action with Turbo Stream responses in app/controllers/accounts_controller.rb
- [ ] T019 [P] [US1] Create I18n translations file config/locales/pt-BR/accounts.yml with all Portuguese strings
- [ ] T020 [P] [US1] Create accounts/new.html.erb view with Turbo Frame modal in app/views/accounts/new.html.erb
- [ ] T021 [P] [US1] Create accounts/_form.html.erb partial with validation hooks in app/views/accounts/_form.html.erb
- [ ] T022 [P] [US1] Implement account_form_controller.js Stimulus controller for client-side validation in app/javascript/controllers/account_form_controller.js
- [ ] T023 [US1] Write request spec for POST /accounts (success and validation errors) in spec/requests/accounts_spec.rb
- [ ] T024 [US1] Write system spec for creating first account (empty state → form → success) in spec/system/accounts_management_spec.rb
- [ ] T025 [US1] Run US1 specs with `bundle exec rspec spec/requests/accounts_spec.rb spec/system/accounts_management_spec.rb`

**Checkpoint**: User Story 1 should be fully functional - users can create their first account

---

## Phase 4: User Story 2 - Visualizar lista de contas com saldos (Priority: P1)

**Goal**: Display all active accounts in a list with current balances, visual indicators for positive/negative balances, and consolidated net worth

**Independent Test**: Create multiple accounts, verify they all appear in the list with correct balances, icons, colors, and total net worth calculation

**Acceptance Scenarios**:
1. User with multiple accounts sees list ordered by creation date with name, icon, color, and balance
2. Positive balances show green indicator, negative balances show red indicator
3. Total net worth sums all account balances correctly
4. Clicking account accesses detail view

### Implementation for User Story 2

- [ ] T026 [US2] Implement AccountsController#index action loading active accounts in app/controllers/accounts_controller.rb
- [ ] T027 [P] [US2] Create accounts/index.html.erb view with account list and totalization in app/views/accounts/index.html.erb
- [ ] T028 [P] [US2] Create accounts/_total.html.erb partial for net worth display in app/views/accounts/_total.html.erb
- [ ] T029 [P] [US2] Create accounts/_account.html.erb partial for account card with balance indicators in app/views/accounts/_account.html.erb
- [ ] T030 [P] [US2] Implement balance_display_controller.js Stimulus controller for formatting in app/javascript/controllers/balance_display_controller.js
- [ ] T031 [US2] Add Turbo Streams subscription for real-time updates in accounts/index.html.erb
- [ ] T032 [US2] Implement AccountsController#show action for account details in app/controllers/accounts_controller.rb
- [ ] T033 [P] [US2] Create accounts/show.html.erb view with account details in app/views/accounts/show.html.erb
- [ ] T034 [US2] Write request spec for GET /accounts (empty state, multiple accounts, archived filtering) in spec/requests/accounts_spec.rb
- [ ] T035 [US2] Write request spec for GET /accounts/:id (success, 404, 403) in spec/requests/accounts_spec.rb
- [ ] T036 [US2] Write system spec for viewing account list with multiple account types in spec/system/accounts_management_spec.rb
- [ ] T037 [US2] Run US2 specs with `bundle exec rspec spec/requests/accounts_spec.rb spec/system/accounts_management_spec.rb`

**Checkpoint**: User Stories 1 AND 2 should both work independently - users can create and view accounts

---

## Phase 5: User Story 5 - Criar múltiplas contas de tipos diferentes (Priority: P1)

**Goal**: Enable users to create multiple accounts of different types (checking and investment) with correct visual differentiation

**Independent Test**: Create checking account, then investment account, verify both appear with distinct icons/colors and independent balances

**Acceptance Scenarios**:
1. User with checking account creates investment account → both appear with distinct icons
2. User creates two checking accounts → both show same icon but different names
3. Total net worth sums both account types correctly
4. Accounts ordered by creation date (most recent first)

### Implementation for User Story 5

- [ ] T038 [US5] Verify Account model account_type enum supports checking and investment (already implemented in T007)
- [ ] T039 [US5] Verify Account model set_icon_and_color callback assigns correct icons/colors (already implemented in T007)
- [ ] T040 [US5] Write system spec for creating multiple accounts of different types in spec/system/accounts_management_spec.rb
- [ ] T041 [US5] Write system spec for creating multiple accounts of same type in spec/system/accounts_management_spec.rb
- [ ] T042 [US5] Write system spec for verifying account ordering by creation date in spec/system/accounts_management_spec.rb
- [ ] T043 [US5] Run US5 specs with `bundle exec rspec spec/system/accounts_management_spec.rb`

**Checkpoint**: User Stories 1, 2, AND 5 should work independently - users have full account creation capabilities

---

## Phase 6: User Story 3 - Editar informações de conta existente (Priority: P2)

**Goal**: Allow users to edit account name and initial balance while preserving transaction history and preventing account type changes

**Independent Test**: Create account, edit name and balance, verify changes saved and account type remains immutable

**Acceptance Scenarios**:
1. User clicks "Edit" on account → form allows changing name and balance, type field disabled
2. User edits initial balance from R$ 1.000 to R$ 1.500 → balance recalculated with transactions preserved
3. User tries to save with empty name → receives validation error
4. Edited account updates immediately for all family members

### Implementation for User Story 3

- [ ] T044 [US3] Implement AccountsController#edit action in app/controllers/accounts_controller.rb
- [ ] T045 [US3] Implement AccountsController#update action with Turbo Stream responses in app/controllers/accounts_controller.rb
- [ ] T046 [P] [US3] Create accounts/edit.html.erb view with Turbo Frame modal in app/views/accounts/edit.html.erb
- [ ] T047 [US3] Update accounts/_form.html.erb partial to disable account_type field when editing in app/views/accounts/_form.html.erb
- [ ] T048 [US3] Add ActionCable broadcast on account update for real-time sync in app/controllers/accounts_controller.rb
- [ ] T049 [US3] Write request spec for GET /accounts/:id/edit in spec/requests/accounts_spec.rb
- [ ] T050 [US3] Write request spec for PATCH /accounts/:id (success, validation errors, immutable type) in spec/requests/accounts_spec.rb
- [ ] T051 [US3] Write system spec for editing account name and balance in spec/system/accounts_management_spec.rb
- [ ] T052 [US3] Write system spec for account type immutability in spec/system/accounts_management_spec.rb
- [ ] T053 [US3] Run US3 specs with `bundle exec rspec spec/requests/accounts_spec.rb spec/system/accounts_management_spec.rb`

**Checkpoint**: User Stories 1, 2, 3, AND 5 should work independently - users can create, view, and edit accounts

---

## Phase 7: User Story 4 - Arquivar conta não utilizada (Priority: P2)

**Goal**: Allow users to archive inactive accounts (soft delete) to hide from main list while preserving transaction history for reports

**Independent Test**: Create account, archive it, verify it disappears from main list but remains accessible in archived view and historical reports

**Acceptance Scenarios**:
1. User archives account → receives confirmation about preserved history
2. Archived account disappears from main listing
3. User accesses "Show archived" filter → sees archived accounts in read-only mode
4. Historical reports include archived account transactions for relevant periods

### Implementation for User Story 4

- [ ] T054 [US4] Implement AccountsController#archive action with Turbo Stream responses in app/controllers/accounts_controller.rb
- [ ] T055 [US4] Implement AccountsController#unarchive action with Turbo Stream responses in app/controllers/accounts_controller.rb
- [ ] T056 [P] [US4] Implement archive_modal_controller.js Stimulus controller for confirmation in app/javascript/controllers/archive_modal_controller.js
- [ ] T057 [US4] Update accounts/index.html.erb to support show_archived parameter and archived section in app/views/accounts/index.html.erb
- [ ] T058 [US4] Update accounts/_account.html.erb partial with archive/unarchive actions in app/views/accounts/_account.html.erb
- [ ] T059 [US4] Add ActionCable broadcast on account archive/unarchive for real-time sync in app/controllers/accounts_controller.rb
- [ ] T060 [US4] Write request spec for DELETE /accounts/:id/archive in spec/requests/accounts_spec.rb
- [ ] T061 [US4] Write request spec for PATCH /accounts/:id/unarchive in spec/requests/accounts_spec.rb
- [ ] T062 [US4] Write system spec for archiving account with confirmation in spec/system/accounts_management_spec.rb
- [ ] T063 [US4] Write system spec for viewing archived accounts in separate section in spec/system/accounts_management_spec.rb
- [ ] T064 [US4] Write system spec for unarchiving account in spec/system/accounts_management_spec.rb
- [ ] T065 [US4] Run US4 specs with `bundle exec rspec spec/requests/accounts_spec.rb spec/system/accounts_management_spec.rb`

**Checkpoint**: All user stories should now be independently functional - complete account lifecycle management

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories, testing validation, and final quality gates

- [ ] T066 [P] Update db/seeds.rb with sample accounts for development in db/seeds.rb
- [ ] T067 [P] Verify Tailwind CSS slate dark theme consistency across all views in app/views/accounts/
- [ ] T068 [P] Verify mobile responsiveness (320px minimum viewport) for all account views
- [ ] T069 [P] Verify desktop viewport (1280px) displays correctly with enhanced layouts
- [ ] T070 [P] Add loading states and spinner indicators for Turbo Stream actions
- [ ] T071 Run full RSpec test suite with `bundle exec rspec` to ensure all tests pass
- [ ] T072 Run Rubocop linting with `bundle exec rubocop -a` to fix violations
- [ ] T073 Run Brakeman security scan with `bundle exec brakeman --no-pager` to check for vulnerabilities
- [ ] T074 Quality Gate Validation: Run `bin/check` and ensure all gates pass (RSpec, Rubocop, Brakeman)
- [ ] T075 Verify maximum test coverage achieved with SimpleCov (target 80%+)
- [ ] T076 Browser Testing: Validate User Story 1 acceptance scenarios with Playwright MCP at mobile viewport (375px)
- [ ] T077 Browser Testing: Validate User Story 1 acceptance scenarios with Playwright MCP at desktop viewport (1280px)
- [ ] T078 Browser Testing: Validate User Story 2 acceptance scenarios with Playwright MCP
- [ ] T079 Browser Testing: Validate User Story 3 acceptance scenarios with Playwright MCP
- [ ] T080 Browser Testing: Validate User Story 4 acceptance scenarios with Playwright MCP
- [ ] T081 Browser Testing: Validate User Story 5 acceptance scenarios with Playwright MCP
- [ ] T082 Verify real-time synchronization works across multiple browser sessions (family members)
- [ ] T083 Performance validation: Verify system handles 50+ accounts without degradation
- [ ] T084 Accessibility validation: Verify keyboard navigation and screen reader compatibility

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - US1 (Phase 3): Create first account - MVP foundation
  - US2 (Phase 4): View account list - Depends on US1 for display
  - US5 (Phase 5): Create multiple accounts - Extends US1 functionality
  - US3 (Phase 6): Edit account - Requires US1 and US2 for context
  - US4 (Phase 7): Archive account - Requires US2 for list filtering
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1 - Phase 3)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1 - Phase 4)**: Depends on US1 (needs accounts to display)
- **User Story 5 (P1 - Phase 5)**: Extends US1 (reuses creation flow, tests multiple types)
- **User Story 3 (P2 - Phase 6)**: Depends on US1 and US2 (needs accounts to edit and view updates)
- **User Story 4 (P2 - Phase 7)**: Depends on US2 (needs list view for filtering archived)

### Within Each User Story

- Controllers before views (views reference controller actions)
- Views before JavaScript controllers (Stimulus controllers target view elements)
- Request specs test controller behavior
- System specs test full user flows with JavaScript
- Each story complete and tested before moving to next priority

### Parallel Opportunities

**Phase 1 (Setup)**:
- T001, T002, T003 can run sequentially (Rails generators must run in order)
- T004 runs after migrations generated

**Phase 2 (Foundational)**:
- T005, T006, T007 (models) can run in parallel - different files
- T008, T009 (factories) can run in parallel after models complete - different files
- T010, T011, T012 (model specs) can run in parallel after factories complete - different files

**Phase 3 (US1)**:
- T015, T016, T019, T020, T021, T022 can run in parallel after T014 - different files
- T023, T024 can run in parallel - different spec files

**Phase 4 (US2)**:
- T027, T028, T029, T030, T033 can run in parallel after T026 - different files
- T034, T035, T036 can run in parallel - different spec files

**Phase 8 (Polish)**:
- T066, T067, T068, T069, T070 can run in parallel - different concerns
- T076-T084 (browser tests) can run in parallel - independent test scenarios

---

## Parallel Example: User Story 1

```bash
# After T014 (routes configured), launch these tasks in parallel:
Task: "Generate AccountsController with rails generate controller"  # T015
Task: "Implement AccountsHelper with balance formatting methods"     # T016
Task: "Create I18n translations file for Portuguese strings"        # T019
Task: "Create accounts/new.html.erb view with Turbo Frame modal"    # T020
Task: "Create accounts/_form.html.erb partial"                      # T021
Task: "Implement account_form_controller.js Stimulus controller"    # T022

# After T017-T022 complete, launch specs in parallel:
Task: "Write request spec for POST /accounts"                       # T023
Task: "Write system spec for creating first account"                # T024
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 + 5 Only - All P1)

1. Complete Phase 1: Setup (T001-T004)
2. Complete Phase 2: Foundational (T005-T013) **CRITICAL - blocks all stories**
3. Complete Phase 3: User Story 1 (T014-T025) - Create first account
4. Complete Phase 4: User Story 2 (T026-T037) - View account list
5. Complete Phase 5: User Story 5 (T038-T043) - Create multiple accounts
6. **STOP and VALIDATE**: Test all P1 stories independently
7. Run browser tests (T076-T078, T081)
8. Deploy MVP if ready

**MVP Value**: Users can create, view, and manage multiple accounts of different types - core functionality complete

### Incremental Delivery (Add P2 Features)

1. Complete MVP (Phases 1-5)
2. Add Phase 6: User Story 3 (T044-T053) - Edit account functionality
3. Test US3 independently, verify US1/US2/US5 still work
4. Add Phase 7: User Story 4 (T054-T065) - Archive account functionality
5. Test US4 independently, verify all previous stories still work
6. Complete Phase 8: Polish (T066-T084)
7. Full feature validation and deployment

### Parallel Team Strategy

With multiple developers (after Phase 2 completes):

**Parallel Track 1** (MVP Critical Path):
- Developer A: US1 (Phase 3) → US2 (Phase 4) sequentially
- These must be sequential as US2 depends on US1

**Parallel Track 2** (MVP Enhancement):
- Developer B: US5 (Phase 5) - Can start after US1 completes

**Parallel Track 3** (P2 Features - after MVP):
- Developer C: US3 (Phase 6) - Can start after US2 completes
- Developer D: US4 (Phase 7) - Can start after US2 completes

**Parallel Track 4** (Polish - after all stories):
- Developer E: Browser testing (T076-T084)
- Developer F: Performance and accessibility (T082-T084)

---

## Notes

- [P] tasks = different files, no dependencies - can be executed simultaneously
- [Story] label maps task to specific user story for traceability (US1-US5)
- Each user story should be independently completable and testable
- Always run specs after implementation to verify functionality
- Use Rails generators for migrations, models, and controllers (Constitution requirement)
- Commit after each task or logical group (not specified per task to reduce verbosity)
- Stop at any checkpoint to validate story independently
- Constitution Principle IV requires comprehensive tests - all specs are mandatory
- Constitution Principle VI requires browser testing with Playwright MCP - T076-T081 are mandatory
- Constitution Principle VIII requires bin/check quality gates - T071-T075 are mandatory
- All code in English, all user-facing text in pt-BR via i18n (Constitution code language conventions)

---

## Task Summary

**Total Tasks**: 84
**Setup**: 4 tasks
**Foundational**: 9 tasks (BLOCKING)
**User Story 1 (P1)**: 12 tasks - Create first account (MVP foundation)
**User Story 2 (P1)**: 12 tasks - View account list (MVP core)
**User Story 5 (P1)**: 6 tasks - Multiple account types (MVP complete)
**User Story 3 (P2)**: 10 tasks - Edit account (enhancement)
**User Story 4 (P2)**: 12 tasks - Archive account (enhancement)
**Polish**: 19 tasks - Quality gates, browser testing, final validation

**MVP Scope (P1)**: T001-T043 (43 tasks) - Core account creation and viewing
**Full Feature Scope**: T001-T084 (84 tasks) - Complete account management lifecycle

**Parallel Opportunities**: 35 tasks marked [P] can run in parallel within their phases
**Independent Stories**: 5 user stories can be developed and tested independently after foundational phase
