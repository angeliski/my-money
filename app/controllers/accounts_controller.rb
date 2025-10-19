class AccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_account, only: [ :show, :edit, :update, :archive, :unarchive ]

  def index
    @accounts = current_user.family.accounts.active.ordered_by_creation
    @archived_accounts = current_user.family.accounts.archived.ordered_by_creation if params[:show_archived]
  end

  def show
  end

  def new
    @account = current_user.family.accounts.build
  end

  def create
    @account = current_user.family.accounts.build(account_params)

    respond_to do |format|
      if @account.save
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("account_modal"),
            turbo_stream.prepend("accounts-list",
                                partial: "accounts/account",
                                locals: { account: @account })
          ]
        end
        format.html { redirect_to accounts_path, notice: t(".success") }
      else
        format.turbo_stream { render :new, status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    if @account.update(account_update_params)
      redirect_to account_path(@account), notice: t(".success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def archive
    @account.archive!
    redirect_to accounts_path, notice: t(".success")
  end

  def unarchive
    @account.unarchive!
    redirect_to accounts_path, notice: t(".success")
  end

  private

  def set_account
    @account = current_user.family.accounts.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to accounts_path, alert: t("accounts.not_found")
  end

  def account_params
    permitted = params.require(:account).permit(:name, :account_type, :initial_balance)
    convert_balance_to_cents(permitted)
  end

  def account_update_params
    # Account type is immutable after creation
    permitted = params.require(:account).permit(:name, :initial_balance)
    convert_balance_to_cents(permitted)
  end

  def convert_balance_to_cents(permitted)
    if permitted[:initial_balance].present?
      # Remove espaços e pontos (separadores de milhares)
      balance_str = permitted[:initial_balance].to_s.strip.gsub(".", "")
      # Converte vírgula em ponto para fazer parse
      balance_str = balance_str.gsub(",", ".")
      # Converte para float e depois para centavos
      balance_float = balance_str.to_f
      permitted[:initial_balance_cents] = (balance_float * 100).round
      permitted.delete(:initial_balance)
    end
    permitted
  end
end
