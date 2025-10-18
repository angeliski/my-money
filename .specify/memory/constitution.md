<!-- Sync Impact Report
Version Change: 1.2.0 → 1.3.0
Modified Principles: None
Added Sections:
- New Principle VII: Visual Consistency and Design System
- Standardized color palette requirement (slate-900 dark theme)
- Component design consistency across all interfaces
- Responsive design validation requirements
Removed Sections: None
Templates Requiring Updates:
- .specify/templates/plan-template.md: ✅ Updated (Constitution Check now includes VII)
- .specify/templates/tasks-template.md: ✅ Updated (Phase 3.5 includes visual consistency validation)
- .specify/templates/spec-template.md: ⚠ No changes needed (visual requirements covered in acceptance scenarios)
- CLAUDE.md: ⚠ Pending manual update (add visual consistency note in Development Notes)
Follow-up TODOs:
- Consider documenting color palette in separate design system file
- Add visual regression testing to CI/CD pipeline
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

### IV. Test-Driven Development
RSpec tests written before implementation. Minimum 80% code coverage maintained.
Integration tests for critical user paths. Model specs validate business logic.
Request specs ensure controller behavior. System specs for JavaScript interactions.

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
devices. This human-in-the-loop validation complements TDD and prevents shipping
features that technically work but deliver poor user experience.

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

## Development Standards

### Technology Stack
- **Backend**: Rails 7.2+ with PostgreSQL (production), SQLite3 (development)
- **Frontend**: Hotwire (Turbo + Stimulus) with Tailwind CSS
- **Testing**: RSpec with FactoryBot, SimpleCov, and System specs
- **Styling**: Tailwind utilities with mobile-first breakpoints
- **JavaScript**: Stimulus controllers for progressive enhancement
- **Browser Testing**: Playwright MCP for manual user acceptance validation

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
- Test coverage maintained
- Performance budgets met
- Migration immutability respected
- Browser testing completed for user-facing features
- Visual consistency maintained across interfaces

Use CLAUDE.md for agent-specific development guidance and operational instructions.

**Version**: 1.3.0 | **Ratified**: 2025-01-28 | **Last Amended**: 2025-10-07
