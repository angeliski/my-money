# Implementation Plan: Gestão de Contas Financeiras

**Branch**: `001-account-management` | **Date**: 2025-10-18 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-account-management/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

This feature implements the financial account management system for MyMoney, enabling users to create, view, edit, and archive checking and investment accounts. The system automatically associates accounts with family entities (invisible to users) and provides real-time balance calculation, visual indicators for positive/negative balances, and comprehensive account listing with consolidated net worth display. The implementation follows Rails conventions with Hotwire for real-time updates, mobile-first responsive design with Tailwind CSS, and comprehensive RSpec testing with browser validation via Playwright.

## Technical Context

**Language/Version**: Ruby 3.3+ with Rails 7.2.2+
**Primary Dependencies**:
- Hotwire (Turbo + Stimulus) for real-time UI updates
- Tailwind CSS for mobile-first responsive styling
- Devise for authentication (already configured)
- money-rails for currency handling (BRL, ROUND_HALF_UP)
- Pagy for pagination
- PaperTrail for audit trail (configured, not yet actively used)

**Storage**:
- SQLite3 (development/test)
- PostgreSQL (production)
- Migrations for schema management

**Testing**:
- RSpec with FactoryBot for test fixtures
- Shoulda Matchers for validation testing
- SimpleCov for code coverage (target: 80% minimum)
- DatabaseCleaner for test isolation
- Playwright MCP for browser-based user acceptance testing

**Target Platform**: Web application (responsive mobile-first design, 320px minimum viewport)

**Project Type**: Web application (Rails monolith with Hotwire)

**Performance Goals**:
- Time to Interactive: <3s on 3G networks
- Largest Contentful Paint: <2.5s
- First Input Delay: <100ms
- Cumulative Layout Shift: <0.1
- Real-time sync: <3 seconds for family member updates

**Constraints**:
- Portuguese (pt-BR) user-facing text via i18n
- English code (variables, methods, classes, comments)
- RESTful English routes (Rails convention)
- Mobile-first with progressive enhancement to desktop
- No deletion of financial records (soft delete/archiving only)
- Minimum 50 accounts per family without performance degradation

**Scale/Scope**:
- Multi-family support (invisible to users in this phase)
- Initial phase: 50+ accounts per family
- Real-time synchronization across family members
- Audit trail for all account operations

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Principle I: Rails Convention over Configuration**
- [x] Using Rails generators for all models, migrations, controllers
  - `rails generate model Family`
  - `rails generate model Account name:string account_type:integer initial_balance_cents:integer color:string icon:string archived_at:datetime family:references`
  - `rails generate controller Accounts`
- [x] Following RESTful routing patterns
  - Standard REST routes: `resources :accounts` with archive action
- [x] Leveraging ActiveRecord patterns appropriately
  - ActiveRecord enums for account_type
  - Scopes for active/archived filtering
  - Associations (belongs_to :family, has_many :accounts)

**Principle II: Mobile-First Progressive Enhancement**
- [x] Mobile viewport (320px minimum) designed first
  - Card-based account list layout optimized for mobile
  - Touch-friendly action buttons with adequate tap targets (44x44px minimum)
- [x] Touch-friendly interfaces
  - Large tap targets, swipe gestures for archive confirmation
- [x] Progressive enhancement to desktop
  - Grid layout on larger screens, additional details visible

**Principle III: Hotwire-Powered Real-time UX**
- [x] Using Turbo for navigation without full page reloads
  - Turbo Frames for account forms (create/edit)
  - Turbo Streams for real-time account list updates
- [x] Stimulus controllers for interactivity
  - Form validation controller
  - Balance display formatting controller
  - Archive confirmation modal controller
- [x] No separate API layer unless justified
  - HTML-first responses with Turbo Streams for updates

**Principle IV: Testing Standards**
- [x] Comprehensive test coverage planned (can be written during/after implementation)
  - Model specs: Account validations, Family associations, balance calculations
  - Request specs: AccountsController CRUD actions, archive action
  - System specs: User flows for all 5 user stories from spec.md
- [x] Minimum 80% code coverage target
  - SimpleCov configured, target set to 80%
- [x] Model, request, and system specs planned
  - spec/models/family_spec.rb, spec/models/account_spec.rb
  - spec/requests/accounts_spec.rb
  - spec/system/accounts_management_spec.rb
- [x] All tests must pass before delivery
  - bin/check will validate before completion

**Principle V: Domain-Driven Design**
- [x] Business logic in models and service objects
  - Account model: balance calculation, archiving logic
  - AccountsFilterService: filtering active/archived accounts
  - Family model: automatic creation during user signup
- [x] Thin controllers
  - AccountsController delegates to models and services
- [x] Clear domain boundaries
  - Family entity manages multi-user context (invisible to users)
  - Account entity encapsulates financial account logic

**Principle VI: User Acceptance Validation via Browser Testing**
- [x] Playwright MCP testing planned for user stories
  - Validate all 5 user stories from spec.md via browser automation
  - Test account creation, listing, editing, archiving flows
- [x] Desktop and mobile viewport validation
  - Test at 375px (mobile) and 1280px (desktop) viewports
- [x] User story validation checklist prepared
  - Checklist maps to acceptance scenarios in spec.md

**Principle VII: Visual Consistency and Design System**
- [x] Using standardized Tailwind slate dark theme colors
  - Background: slate-900, slate-800
  - Borders: slate-700
  - Text: white, gray-400
  - Accent: cyan-600, cyan-400
  - Status: green-600 (positive balance), red-600 (negative balance)
- [x] Following existing component patterns
  - Reuse existing button, form, modal, card components
- [x] Responsive design validation planned
  - Mobile-first with responsive breakpoints (sm, md, lg, xl)

**Principle VIII: Quality Gates and Delivery Standards**
- [x] bin/check compliance planned (RSpec, Rubocop, Brakeman)
  - All tests pass before delivery
  - Rubocop auto-fix applied
  - Brakeman security scan clean
- [x] Maximum test coverage strategy defined
  - Target 80%+ coverage on models, controllers, services
  - System specs for critical user paths
- [x] Quality gate validation in final phase
  - bin/check execution as final delivery gate

## Project Structure

### Documentation (this feature)

```
specs/001-account-management/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```
app/
├── models/
│   ├── family.rb                    # Family entity (invisible to users)
│   ├── account.rb                   # Account entity with balance calculation
│   └── user.rb                      # Extended with family association
├── controllers/
│   └── accounts_controller.rb       # RESTful CRUD + archive action
├── services/
│   └── accounts_filter_service.rb   # Filter active/archived accounts
├── views/
│   └── accounts/
│       ├── index.html.erb           # List view with totalization
│       ├── new.html.erb             # Create form
│       ├── edit.html.erb            # Edit form
│       ├── show.html.erb            # Account details
│       └── _form.html.erb           # Shared form partial
├── javascript/
│   └── controllers/
│       ├── account_form_controller.js      # Client-side validation
│       ├── balance_display_controller.js   # Balance formatting
│       └── archive_modal_controller.js     # Archive confirmation
└── assets/
    └── stylesheets/
        └── accounts.css             # Account-specific Tailwind utilities

db/
├── migrate/
│   ├── [timestamp]_create_families.rb
│   ├── [timestamp]_create_accounts.rb
│   └── [timestamp]_add_family_to_users.rb
└── seeds.rb                         # Extended with sample accounts

spec/
├── models/
│   ├── family_spec.rb               # Family model tests
│   └── account_spec.rb              # Account model tests
├── requests/
│   └── accounts_spec.rb             # AccountsController request tests
├── system/
│   └── accounts_management_spec.rb  # End-to-end user story tests
├── factories/
│   ├── families.rb                  # FactoryBot family fixtures
│   └── accounts.rb                  # FactoryBot account fixtures
└── support/
    └── shared_examples/
        └── archivable.rb            # Shared archiving behavior tests

config/
├── routes.rb                        # Extended with accounts routes
└── locales/
    └── pt-BR/
        └── accounts.yml             # Portuguese translations for accounts
```

**Structure Decision**: Rails monolith structure (standard Rails MVC pattern). The feature follows standard Rails conventions with models in `app/models/`, controllers in `app/controllers/`, views in `app/views/accounts/`, and Stimulus controllers in `app/javascript/controllers/`. Tests follow RSpec conventions under `spec/` directory with model, request, and system specs. Database migrations use Rails generators for schema changes. All user-facing text uses Rails i18n with pt-BR locale files.

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

No constitution violations detected. All principles are satisfied by the planned implementation.

