# Service to recalculate account balances based on transactions
class BalanceCalculator
  def self.recalculate(account)
    return unless account

    transfer_category = Category.find_by(name: "Transferência")

    # Income (excluding transfers)
    income = account.transactions
                    .where(transaction_type: "income")
                    .where.not(category: transfer_category)
                    .sum(:amount_cents)

    # Expense (excluding transfers)
    expense = account.transactions
                     .where(transaction_type: "expense")
                     .where.not(category: transfer_category)
                     .sum(:amount_cents)

    # Include transfers in balance calculation
    transfer_income = account.transactions
                             .where(transaction_type: "income", category: transfer_category)
                             .sum(:amount_cents)

    transfer_expense = account.transactions
                              .where(transaction_type: "expense", category: transfer_category)
                              .sum(:amount_cents)

    # Calculate new balance: initial + income - expense + transfer_in - transfer_out
    new_balance = account.initial_balance_cents + income - expense + transfer_income - transfer_expense

    # Update balance using update_column to skip callbacks
    account.update_column(:balance_cents, new_balance) if account.respond_to?(:balance_cents)
  end
end
