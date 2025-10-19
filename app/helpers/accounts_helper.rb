module AccountsHelper
  def total_net_worth
    total_cents = current_user.family.accounts.active.sum { |account| account.current_balance.cents }
    number_to_currency(Money.new(total_cents, "BRL"), locale: :'pt-BR')
  end

  def format_balance(account)
    number_to_currency(account.current_balance, locale: :'pt-BR')
  end

  def balance_class(account)
    account.positive_balance? ? "text-green-600" : "text-red-600"
  end

  def account_type_options
    Account.account_types.keys.map do |type|
      [ t("accounts.form.account_types.#{type}"), type ]
    end
  end
end
