# Service to handle transfers between accounts
class TransferService
  def self.create_transfer(from_account:, to_account:, amount_cents:, transaction_date:, description:, user:)
    # Validations
    raise ArgumentError, "De e Para devem ser contas diferentes" if from_account.id == to_account.id
    raise ArgumentError, "Conta de origem não encontrada ou arquivada" if from_account.archived?
    raise ArgumentError, "Conta de destino não encontrada ou arquivada" if to_account.archived?

    transfer_category = Category.find_by!(name: "Transferência")

    ActiveRecord::Base.transaction do
      # Create expense in source account
      expense = Transaction.create!(
        transaction_type: "expense",
        amount_cents: amount_cents,
        transaction_date: transaction_date,
        description: description,
        account: from_account,
        category: transfer_category,
        user: user,
        is_template: false
      )

      # Create income in destination account
      income = Transaction.create!(
        transaction_type: "income",
        amount_cents: amount_cents,
        transaction_date: transaction_date,
        description: description,
        account: to_account,
        category: transfer_category,
        user: user,
        is_template: false
      )

      # Link them
      expense.update!(linked_transaction: income)
      income.update!(linked_transaction: expense)

      [ expense, income ]
    end
  end
end
