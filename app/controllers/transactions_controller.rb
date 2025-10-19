class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction, only: [ :edit, :update, :destroy, :mark_as_paid, :unmark_as_paid ]
  before_action :set_filter_data, only: [ :index, :new, :edit ]

  def index
    @month = params[:month] || Date.current.strftime("%Y-%m")

    @transactions = current_user.family.transactions
                                .includes(:account, :category, :user)
                                .apply_filters(filter_params)

    # Apply month filter if no custom period specified
    unless filter_params[:period_start].present? && filter_params[:period_end].present?
      @transactions = @transactions.by_month(@month)
    end

    @transactions = @transactions.order(transaction_date: :desc, created_at: :desc)

    # Pagination
    @pagy, @transactions = pagy(@transactions, items: 50)

    # Calculate totals for current filter
    @totals = calculate_totals(@transactions)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def new
    @transaction = Transaction.new(
      transaction_date: Date.current,
      currency: "BRL"
    )

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def create
    @transaction = Transaction.new(transaction_params)
    @transaction.user = current_user

    respond_to do |format|
      if @transaction.save
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("transaction_modal"),
            turbo_stream.prepend("transactions_list",
                                 partial: "transactions/transaction",
                                 locals: { transaction: @transaction }),
            turbo_stream.update("account_#{@transaction.account_id}_balance",
                               partial: "accounts/balance_badge",
                               locals: { account: @transaction.account })
          ]
        end
        format.html { redirect_to transactions_path, notice: "Transação criada com sucesso." }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("transaction_modal",
                                                     partial: "transactions/modal_form",
                                                     locals: { transaction: @transaction })
        end
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def update
    respond_to do |format|
      if @transaction.update(transaction_params)
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("transaction_modal"),
            turbo_stream.replace("transaction_#{@transaction.id}",
                                partial: "transactions/transaction",
                                locals: { transaction: @transaction }),
            turbo_stream.update("account_#{@transaction.account_id}_balance",
                               partial: "accounts/balance_badge",
                               locals: { account: @transaction.account })
          ]
        end
        format.html { redirect_to transactions_path, notice: "Transação atualizada com sucesso." }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("transaction_modal",
                                                     partial: "transactions/modal_form",
                                                     locals: { transaction: @transaction })
        end
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    account = @transaction.account
    @transaction.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove("transaction_#{@transaction.id}"),
          turbo_stream.update("account_#{account.id}_balance",
                             partial: "accounts/balance_badge",
                             locals: { account: account })
        ]
      end
      format.html { redirect_to transactions_path, notice: "Transação excluída com sucesso." }
    end
  end

  def mark_as_paid
    @transaction.mark_as_paid!
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("transaction_#{@transaction.id}",
                              partial: "transactions/transaction",
                              locals: { transaction: @transaction }),
          turbo_stream.update("account_#{@transaction.account_id}_balance",
                             partial: "accounts/balance_badge",
                             locals: { account: @transaction.account })
        ]
      end
      format.html { redirect_to transactions_path, notice: "Transação marcada como paga." }
    end
  rescue StandardError => e
    respond_to do |format|
      format.html { redirect_to transactions_path, alert: e.message }
    end
  end

  def unmark_as_paid
    @transaction.unmark_as_paid!
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("transaction_#{@transaction.id}",
                              partial: "transactions/transaction",
                              locals: { transaction: @transaction }),
          turbo_stream.update("account_#{@transaction.account_id}_balance",
                             partial: "accounts/balance_badge",
                             locals: { account: @transaction.account })
        ]
      end
      format.html { redirect_to transactions_path, notice: "Marcação removida." }
    end
  rescue StandardError => e
    respond_to do |format|
      format.html { redirect_to transactions_path, alert: e.message }
    end
  end

  private

  def set_transaction
    @transaction = current_user.family.transactions.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to transactions_path, alert: "Transação não encontrada"
  end

  def set_filter_data
    @accounts = current_user.family.accounts.active.ordered_by_creation
    @categories = Category.all.order(:name)
  end

  def transaction_params
    params.require(:transaction).permit(
      :transaction_type,
      :amount,
      :transaction_date,
      :description,
      :category_id,
      :account_id,
      :is_template,
      :frequency,
      :start_date,
      :end_date
    )
  end

  def filter_params
    params.permit(:transaction_type_filter, :category_id, :account_id, :status, :search, :period_start, :period_end)
  end

  def calculate_totals(transactions)
    transfer_category = Category.find_by(name: "Transferência")

    {
      count: transactions.count,
      income: transactions.income_transactions.where.not(category: transfer_category).sum(:amount_cents),
      expense: transactions.expense_transactions.where.not(category: transfer_category).sum(:amount_cents)
    }
  end
end
