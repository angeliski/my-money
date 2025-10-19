class TransfersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_accounts, only: [ :new, :create ]

  def new
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def create
    from_account = current_user.family.accounts.find(transfer_params[:from_account_id])
    to_account = current_user.family.accounts.find(transfer_params[:to_account_id])
    amount_cents = (transfer_params[:amount].to_f * 100).to_i

    expense, income = TransferService.create_transfer(
      from_account: from_account,
      to_account: to_account,
      amount_cents: amount_cents,
      transaction_date: transfer_params[:transaction_date],
      description: transfer_params[:description],
      user: current_user
    )

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove("transaction_modal"),
          turbo_stream.prepend("transactions_list",
                               partial: "transactions/transaction",
                               locals: { transaction: expense }),
          turbo_stream.prepend("transactions_list",
                               partial: "transactions/transaction",
                               locals: { transaction: income }),
          turbo_stream.update("account_#{from_account.id}_balance",
                             partial: "accounts/balance_badge",
                             locals: { account: from_account }),
          turbo_stream.update("account_#{to_account.id}_balance",
                             partial: "accounts/balance_badge",
                             locals: { account: to_account })
        ]
      end
      format.html { redirect_to transactions_path, notice: "Transferência criada com sucesso." }
    end
  rescue ArgumentError => e
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("transaction_modal",
                                                   partial: "transfers/modal_form",
                                                   locals: { error: e.message })
      end
      format.html { redirect_to transactions_path, alert: e.message }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to transactions_path, alert: "Conta não encontrada" }
    end
  end

  private

  def set_accounts
    @accounts = current_user.family.accounts.active.ordered_by_creation
  end

  def transfer_params
    params.require(:transfer).permit(
      :from_account_id,
      :to_account_id,
      :amount,
      :transaction_date,
      :description
    )
  end
end
