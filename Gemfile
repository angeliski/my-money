source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.2.2", ">= 7.2.2.1"
gem "rails-i18n", "~> 7.0.0" # For Rails >= 7.0.0

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"
# Use sqlite3 as the database for Active Record in development and test
gem "sqlite3", ">= 1.4", group: [ :development, :test ]
# PostgreSQL for production
gem "pg", "~> 1.0", group: :production
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"
# Use Redis adapter to run Action Cable in production
# gem "redis", ">= 4.0.1"

# Use Solid Cable for Action Cable in production
gem "solid_cable"

# Charts and data visualization
gem "chartkick"
gem "groupdate"

# Export formats for analytics
gem "caxlsx"              # Excel export
gem "prawn"               # PDF export
gem "prawn-table"         # PDF tables

# Pagination
gem "pagy", "~> 9.0"

# Audit trail for tracking changes
gem "paper_trail", "~> 17.0"

# Money handling for financial transactions
gem "money-rails", "~> 1.15"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Authentication with Devise
gem "devise"
gem "devise-i18n"
gem "devise-tailwindcssed"
gem "devise_invitable", "~> 2.0.0"


# email sending via Resend
gem "resend"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # RSpec testing framework
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "shoulda-matchers"
  gem "database_cleaner-active_record"
  gem "rails-controller-testing"
  gem "simplecov", require: false # coverage report
  gem "simplecov_json_formatter", "~> 0.1.4" # format coverage report
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
  gem "foreman"
end
