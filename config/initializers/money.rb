# frozen_string_literal: true

# Money Rails configuration
MoneyRails.configure do |config|
  # Set default currency
  config.default_currency = :brl

  # Set default bank object
  # config.default_bank = EuCentralBank.new

  # Add exchange rates to current Money bank object
  # config.add_rate "USD", "CAD", 1.25

  # To handle money from different locales,
  # you can set custom exchange attributes
  # config.amount_column = {
  #   postfix: '_cents',
  #   type: :integer,
  #   present: true
  # }

  # Specify a rounding mode
  config.rounding_mode = BigDecimal::ROUND_HALF_UP

  # Set the locale for money formatting
  config.locale_backend = :i18n

  # Configure sign before symbol (R$ -100,00 instead of -R$ 100,00)
  config.sign_before_symbol = false
end

# Use local formatting for money
Money.locale_backend = :i18n
Money.rounding_mode = BigDecimal::ROUND_HALF_UP
