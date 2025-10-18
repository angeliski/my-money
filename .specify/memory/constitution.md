<!-- Sync Impact Report
Version Change: 1.4.0 → 1.5.0
Modified Principles:
- Principle IV: Test-Driven Development → Testing Standards
  - Removed requirement for tests to be written before implementation (TDD)
  - Changed to require comprehensive tests completed by delivery time
  - Maintained coverage and quality standards
- Principle VIII: Quality Gates and Delivery Standards
  - Removed TDD workflow reference from quality validation
  - Clarified tests must pass before delivery (not written first)
- Development Standards: Code Language Conventions (NEW)
  - Clarified code must be in English (variables, methods, classes, comments)
  - User-facing text remains pt-BR via i18n
  - Routes follow Rails English conventions for REST consistency
Added Sections:
- Code Language Conventions under Development Standards
Removed Sections: None
Templates Requiring Updates:
- .specify/templates/plan-template.md: ✅ Updated (Principle IV Constitution Check updated)
- .specify/templates/tasks-template.md: ✅ Already flexible (mentions tests are optional)
- .specify/templates/spec-template.md: ✅ No changes needed (spec stays technology-agnostic)
Follow-up TODOs:
- Ensure development team understands testing comes at end, not beginning
- Clarify in onboarding docs that code language is English despite pt-BR user text
-->

# MyMoney Constitution

## Core Principles

### I. Rails Convention over Configuration
Every feature follows Rails conventions and best practices. Utilize Rails built-in
functionality before introducing external dependencies. Leverage Rails generators,
ActiveRecord patterns, and RESTful routing.

**Generator-First Approach**: ALWAYS use Rails generators for creating files:
- Models: `rails generate model ModelName field:type`
- Migrations: `rails generate migration AddFieldToTable field:type`
- Controllers: `rails generate controller ControllerName actions`
- Scaffolds: Consider `rails generate scaffold` when creating full CRUD resources

**NEVER** create migration files manually. The timestamp prefix is critical for
execution order and manual creation breaks this guarantee.

Custom solutions require explicit justification when deviating from Rails Way.

### II. Mobile-First Progressive Enhancement
All interfaces designed for mobile viewport first (320px minimum). Features must
work on touch devices without compromise. Desktop experience enhances mobile base
through responsive breakpoints. Performance optimized for mobile networks with
lazy loading and minimal JavaScript payloads.

### III. Hotwire-Powered Real-time UX
Turbo and Stimulus handle all interactivity without full page reloads. Server
rendering maintains SEO and accessibility. WebSocket connections via Turbo Streams
for live updates. No separate API layer unless external consumers require it.

### IV. Testing Standards
All code MUST have comprehensive test coverage completed before delivery. RSpec
tests validate all business logic, controller behavior, and user interactions.
Minimum 80% code coverage maintained across the codebase.

**Testing Requirements**:
- **Model Specs**: Validate all business logic, validations, associations, and scopes
- **Request Specs**: Ensure controller actions behave correctly across all HTTP methods
- **System Specs**: Cover critical user paths with JavaScript interactions via browser automation
- **Coverage Target**: Minimum 80% code coverage measured by SimpleCov
- **Delivery Gate**: All tests MUST pass before feature is considered complete

**Test Development Approach**:
- Tests can be written before, during, or after implementation
- Tests MUST be comprehensive and complete by delivery time
- All new code paths MUST have corresponding test coverage
- Existing tests MUST continue passing (no regressions)

**Rationale**: Comprehensive testing ensures code reliability, facilitates refactoring,
documents expected behavior, and prevents regressions. The timing of test writing
is flexible, but test completeness and quality are non-negotiable delivery requirements.

### V. Domain-Driven Design
Business logic encapsulated in models and service objects. Controllers remain thin
coordinators. Views contain minimal logic via helpers and components. Clear
separation between terminal types and their capabilities. Stock and financial
operations maintain audit trails.

### VI. User Acceptance Validation via Browser Testing
When a feature specification is completed, manual browser testing MUST be performed
using the Playwright MCP tool to validate user-facing behaviors from the end-user
perspective. Testing validates the user stories defined in the original specification
document.

**Testing Requirements**:
- Execute browser tests after all automated tests pass
- Validate all user stories from the feature spec via browser interaction
- Test both desktop and mobile viewports to ensure responsive behavior
- Verify actual user interface and interactions, not just logs or console output
- Document any discrepancies between expected and actual behavior

**Rationale**: Automated tests validate code behavior but cannot capture the full
user experience. Browser testing ensures features work as intended from the user's
perspective, catches visual regressions, and validates responsive design across
devices. This human-in-the-loop validation complements automated testing and prevents
shipping features that technically work but deliver poor user experience.

### VII. Visual Consistency and Design System
All user interfaces MUST maintain consistent visual identity across the entire
application. Color schemes, typography, spacing, component design, and interaction
patterns MUST be uniform to deliver a cohesive and refined user experience.

**Visual Identity Requirements**:
- **Color Palette**: Use the standardized dark theme based on Tailwind slate colors
  - Primary background: `slate-900`
  - Secondary background: `slate-800`
  - Borders and dividers: `slate-700`
  - Text primary: `white`
  - Text secondary: `gray-400`
  - Accent: `cyan-600` for interactive elements, `cyan-400` for highlights
  - Success: `green-600`, Warning: `yellow-600`, Error: `red-600`
- **Component Consistency**: Buttons, forms, modals, cards, and tables MUST follow
  the same design patterns across all views
- **Spacing and Layout**: Maintain consistent padding, margins, and grid systems
  using Tailwind utilities
- **Typography**: Use standardized font sizes, weights, and line heights

**UX Consistency Requirements**:
- Navigation patterns MUST be predictable across all sections
- Form validation and error messages MUST follow the same format
- Loading states and feedback MUST use consistent indicators
- Modal and overlay behaviors MUST be uniform
- Responsive breakpoints and mobile interactions MUST work identically

**Validation Process**:
- Every new view or component MUST be compared against existing patterns
- Visual testing MUST validate both desktop (1280px+) and mobile (375px) viewports
- Changes to shared components require review of all usage contexts
- Color deviations require explicit justification and design approval

**Rationale**: Inconsistent interfaces create cognitive load, reduce user trust,
and degrade perceived quality. A unified design system ensures users can navigate
efficiently, reduces development time through reusable patterns, and maintains
professional presentation across all features. Visual consistency is a core quality
attribute, not a cosmetic afterthought.

### VIII. Quality Gates and Delivery Standards
All implementations MUST pass mandatory quality gates before delivery. The
`bin/check` script defines the complete quality validation suite and MUST pass
without errors or warnings. Code coverage MUST be maximized at all times.

**Mandatory Quality Gates**:
- **Test Suite**: All RSpec tests MUST pass with documentation format output
  - Command: `bundle exec rspec --format documentation --color`
  - Zero failures, zero pending specs allowed in deliveries
  - All new code MUST have corresponding test coverage
  - Tests must be complete before delivery (can be written anytime during development)
- **Code Quality**: Rubocop linting MUST pass with auto-fix applied
  - Command: `bundle exec rubocop -f github -a`
  - Follow Rails Omakase style guide without exceptions
  - All violations MUST be resolved before delivery
- **Security Scanning**: Brakeman security analysis MUST report zero vulnerabilities
  - Command: `bundle exec brakeman --no-pager`
  - All security warnings MUST be addressed or explicitly justified
- **Code Coverage**: Test coverage MUST be maximized
  - Strive for highest possible coverage on all code paths
  - New features MUST NOT decrease overall coverage percentage
  - SimpleCov reports MUST show comprehensive coverage across all groups

**Quality Validation Workflow**:
1. Implement feature with tests (tests can be written before, during, or after implementation)
2. Ensure all tests pass and coverage is comprehensive
3. Run `bin/check` to validate all quality gates
4. Fix any test failures, linting violations, or security issues
5. Verify coverage reports show comprehensive testing
6. Only mark implementation complete when `bin/check` passes cleanly

**Rationale**: Quality gates prevent technical debt accumulation and ensure
maintainable, secure, well-tested code. The `bin/check` script provides a
single command to validate all quality requirements, enabling fast feedback
and preventing broken code from reaching production. Maximum test coverage
ensures code reliability, facilitates refactoring, and documents expected
behavior. These gates are non-negotiable - code that doesn't pass is not
considered complete.

## Development Standards

### Technology Stack
- **Backend**: Rails 7.2+ with PostgreSQL (production), SQLite3 (development)
- **Frontend**: Hotwire (Turbo + Stimulus) with Tailwind CSS
- **Testing**: RSpec with FactoryBot, SimpleCov, and System specs
- **Styling**: Tailwind utilities with mobile-first breakpoints
- **JavaScript**: Stimulus controllers for progressive enhancement
- **Browser Testing**: Playwright MCP for manual user acceptance validation

### Code Language Conventions

**Code Language**: English
- All code MUST be written in English:
  - Variable names: `user_account`, `total_balance` (not `conta_usuario`, `saldo_total`)
  - Method names: `calculate_balance`, `process_transaction` (not `calcular_saldo`, `processar_transacao`)
  - Class names: `BankAccount`, `TransactionProcessor` (not `ContaBancaria`, `ProcessadorTransacao`)
  - Comments: English explanations of complex logic
  - Database columns: `created_at`, `user_id` (not `criado_em`, `usuario_id`)

**User-Facing Text**: Portuguese (pt-BR)
- All text shown to users MUST be in Portuguese via Rails i18n:
  - View templates: Use `t('key')` for all strings
  - Flash messages: `t('flash.success')` not hardcoded English
  - Error messages: Configured in `config/locales/pt-BR.yml`
  - Email templates: All content in Portuguese

**Routes**: English (Rails Convention)
- Follow Rails RESTful conventions in English for consistency:
  - `/accounts` not `/contas` for accounts resource
  - `/transactions` not `/transacoes` for transactions resource
  - `/users/sign_in` not `/usuarios/entrar` for Devise routes
- Standard Rails route helpers: `account_path`, `new_transaction_path`

**Rationale**: English code ensures:
- Compatibility with international Rails community and gems
- Consistency with Rails framework conventions and documentation
- Easier collaboration with English-speaking developers
- Standard route patterns familiar to all Rails developers
- Clear separation: code (technical, English) vs. UI (user-facing, pt-BR)

### Migration Management

**Creation Rules**:
- ALWAYS use `rails generate migration` or `rails generate model` commands
- NEVER create migration files manually in `db/migrate/`
- Migration filename timestamps ensure correct execution order
- Use descriptive migration names: `AddEmailToUsers`, `CreateSalesTable`

**Immutability Rules**:
- NEVER alter migrations already applied to production databases
- NEVER alter migrations committed to the `main` branch
- To fix migration errors: Create a NEW migration with corrective changes
- Rollback is acceptable only in development/local environments

**Rationale**: Manual migration creation bypasses timestamp generation, breaking
execution order guarantees. Altering committed migrations causes database
inconsistency across environments and team members. Migration history must be
append-only to maintain reproducibility.

### Code Quality Requirements
- Rubocop Rails Omakase style enforced
- Brakeman security scanning on every PR
- Database migrations reversible and data-safe
- N+1 queries prevented with bullet gem in development
- Strong parameters and CSRF protection enabled

## User Experience Standards

### Performance Targets
- Time to Interactive: <3s on 3G networks
- Largest Contentful Paint: <2.5s
- First Input Delay: <100ms
- Cumulative Layout Shift: <0.1
- Bundle size: <200KB gzipped JavaScript


## Governance

This constitution supersedes all development practices and architectural decisions.
All pull requests must demonstrate compliance with stated principles. Amendments
require documented justification, team consensus, and migration plan for existing
code. Technical debt explicitly tracked when principles cannot be immediately
satisfied.

Code reviews verify:
- Rails conventions followed (including generator usage)
- Mobile viewport tested
- Hotwire patterns utilized
- Test coverage maintained and comprehensive by delivery
- Performance budgets met
- Migration immutability respected
- Browser testing completed for user-facing features
- Visual consistency maintained across interfaces
- Quality gates passed (bin/check succeeds)
- Code written in English, user text in pt-BR via i18n

Use CLAUDE.md for agent-specific development guidance and operational instructions.

**Version**: 1.5.0 | **Ratified**: 2025-01-28 | **Last Amended**: 2025-10-18
