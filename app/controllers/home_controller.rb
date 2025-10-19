class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @month = params[:month] ? Date.parse("#{params[:month]}-01") : Date.today.beginning_of_month

    # Total balance across all accounts
    @total_balance = Account.sum(:balance_cents)

    # Monthly income and expenses
    start_date = @month.beginning_of_month
    end_date = @month.end_of_month

    @monthly_income = Transaction
      .where(transaction_type: "income")
      .where(transaction_date: start_date..end_date)
      .sum(:amount_cents)

    @monthly_expenses = Transaction
      .where(transaction_type: "expense")
      .where(transaction_date: start_date..end_date)
      .sum(:amount_cents)

    # Accounts ordered by balance
    @accounts = Account.order(balance_cents: :desc)
  end
end
