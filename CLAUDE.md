# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MyMoney is a Ruby on Rails 7.2 family financial control application designed to help users manage their personal finances through an intuitive interface. The application focuses on transaction management, categorization, recurring transactions, and investment tracking.

**Primary Language:** Portuguese (Brazil) - `pt-BR`
**Timezone:** America/Sao_Paulo
**Database:** SQLite3 (dev/test), PostgreSQL (production)

## Core Domain Concepts

### Financial Transaction System
- **Accounts:** Two types - Corrente (Checking) and Investimentos (Investments)
  - Each account tracks balance calculated from transactions
  - Accounts use archiving instead of deletion for historical integrity
  - Initial balance doesn't count toward income/expense reports

- **Transactions:** Income and expenses with two patterns
  1. **Pontual (One-time):** Single transaction
  2. **Recorrente (Recurring/Template):** Creates future transactions automatically
     - Templates generate transactions up to 12 months ahead
     - Once effectuated (date reached), transactions become independent
     - Template edits only affect future non-effectuated transactions

- **Categories:** Pre-seeded on user creation
  - Despesas (Expenses): 11 categories including Moradia, Contas, Alimentação, etc.
  - Receitas (Income): 5 categories including Salário, Freelance, Rendimentos, etc.
  - Support custom categories with archiving (not deletion)

- **Investments:** Simplified tracking without brokerage integration
  - Three movement types: Aporte (contribution), Rendimento (yield), Resgate (withdrawal)
  - Calculates rentability: (Rendimentos / Total Aportado) × 100

### Money Handling
- Uses `money-rails` gem with BRL as default currency
- Rounding mode: `ROUND_HALF_UP`
- Amount stored in cents (integer columns with `_cents` postfix)
- i18n-backed locale formatting

## Development Commands

### Setup
```bash
bundle install                    # Install dependencies
bin/rails db:create              # Create database
bin/rails db:migrate             # Run migrations
bin/rails db:seed                # Seed database with initial data
```

### Running the Application
```bash
bin/dev                          # Start server with Tailwind CSS watcher (via Foreman)
                                 # Runs on port 3000 by default (configurable via PORT env var)
```

The `bin/dev` script uses Foreman to run:
- Rails server (`bin/rails server`)
- Tailwind CSS watcher (`bin/rails tailwindcss:watch`)

### Testing
```bash
bundle exec rspec                # Run all tests
bundle exec rspec spec/models/   # Run model tests
bundle exec rspec spec/path/to/file_spec.rb        # Run specific file
bundle exec rspec spec/path/to/file_spec.rb:123    # Run specific test by line number
```

**Test Configuration:**
- Framework: RSpec with FactoryBot, Shoulda Matchers
- Coverage: SimpleCov (configured in `spec/rails_helper.rb`)
- Database: DatabaseCleaner for test isolation
- Coverage groups: Models, Controllers, Services, Views, Helpers

### Code Quality
```bash
bundle exec rubocop              # Run linter
bin/rubocop -a                   # Auto-fix violations
bundle exec brakeman             # Security vulnerability scan
```

Follows Rails Omakase rubocop configuration.

### Database
```bash
bin/rails db:migrate             # Run pending migrations
bin/rails db:rollback            # Rollback last migration
bin/rails db:test:prepare        # Prepare test database
bin/rails generate migration MigrationName   # Create new migration
```

## Architecture

### Tech Stack
- **Backend:** Ruby on Rails 7.2.2+
- **Frontend:** Hotwire (Turbo + Stimulus), Tailwind CSS, Importmap
- **Authentication:** Devise with Devise Invitable
- **Authorization:** Enum-based roles (admin/member) with status tracking
- **Real-time:** Action Cable with Solid Cable
- **Charting:** Chartkick + Groupdate
- **Exports:** Caxlsx (Excel), Prawn (PDF)
- **Pagination:** Pagy
- **Audit Trail:** PaperTrail (configured but not yet actively used)

### Application Structure

**Models:** Standard Rails models in `app/models/`
- User: Devise-based with invitation system, roles (admin/member), status (active/disabled/blocked/invited)
- Category: Name-based with uniqueness validation
- More models to be added per PRD (Account, Transaction, etc.)

**Controllers:** RESTful controllers in `app/controllers/`
- Use standard Rails conventions
- Portuguese route paths (e.g., `/usuarios` for users)

**Services:** Business logic extracted to `app/services/`
- Pattern: `[Domain]Service` (e.g., `UsersFilterService`)
- Keep controllers thin, move complex logic to services

**Views:** ERB templates with Tailwind CSS
- Uses Devise pre-styled with `devise-tailwindcssed`
- Application layout includes SVG icon system

### Key Configuration Files
- `config/initializers/money.rb` - Money/currency settings
- `config/initializers/devise.rb` - Authentication configuration
- `config/initializers/pagy.rb` - Pagination settings
- `config/initializers/docker_secrets.rb` - Docker secret loading for production
- `config/application.rb` - Sets pt-BR locale and São Paulo timezone

### User System
- **Roles:** admin (Administrador), member (Membro) - default: member
- **Status:** active, disabled, blocked, invited - default: invited
- **Invitation Flow:** Uses Devise Invitable, status changes to active upon acceptance
- **Validations:** Email uniqueness, secure password via Devise

## Deployment

Application is containerized with Docker and uses docker-compose for production deployment. Secrets are managed via Docker secrets:
- `database_url`
- `app_url`
- `secret_key_base`
- `mailer_sender`
- `resend_api_key`

Email delivery uses Resend service.

## Development Conventions

### Localization
- All user-facing text must be in Portuguese (pt-BR)
- Use Rails i18n for all strings
- Models and controllers may use English for code, but views/user content uses Portuguese

### Database
- Prefer archiving over deletion (use status/archived_at columns)
- Maintain historical integrity - never delete financial records
- Use proper foreign keys and indexes

### Testing
- Write tests for all business logic in services
- Use FactoryBot for test data
- Keep test coverage high (target not yet set in SimpleCov config)

### Front-end
- Use Stimulus controllers for interactive behavior
- Turbo for SPA-like navigation
- Tailwind utility classes for styling (no custom CSS unless necessary)
- Chartkick for data visualization

## Project Roadmap (from PRD)

The application is implementing a comprehensive family financial control system. Key features include:
- Multi-account management (checking and investment accounts)
- Transaction tracking with recurring transaction templates
- Category-based expense tracking with budgeting
- Investment portfolio tracking with performance metrics
- Visual dashboards and reports
- Cash flow projections based on recurring transactions
- Mobile-first responsive design

Refer to `docs/PRD.md` for complete feature specifications and business rules.
