require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)


# Load Docker Secrets before Rails configuration
# This ensures ENV vars are available when config/environments/*.rb files are loaded
if ENV["RAILS_ENV"] == "production"
  secrets_path = "/run/my_money"
  # lets log information here to STDOUT for visibility in container logs
  puts "Loading Docker secrets from #{secrets_path}..."

  if Dir.exist?(secrets_path)
    Dir.foreach(secrets_path) do |secret_file|
      next if secret_file == "." || secret_file == ".."

      secret_file_path = File.join(secrets_path, secret_file)

      if File.file?(secret_file_path) && File.readable?(secret_file_path)
        env_key = secret_file.upcase
        ENV[env_key] = File.read(secret_file_path).strip
        puts "Loaded secret for ENV key: #{env_key}"
      else
        puts "Skipping unreadable file: #{secret_file_path}"
      end
    end
  else
    puts "Secrets directory #{secrets_path} does not exist. Skipping loading Docker secrets."
  end
end
module MyMoney
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.

    # Set timezone to Brazil
    config.time_zone = "America/Sao_Paulo"

    # Set default locale to Portuguese Brazil
    config.i18n.default_locale = :'pt-BR'
    config.i18n.available_locales = [ :'pt-BR', :en ]

    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil
  end
end
