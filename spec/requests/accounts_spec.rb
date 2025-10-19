require 'rails_helper'

RSpec.describe "Accounts", type: :request do
  let(:user) { create(:user, status: :active) }
  let(:family) { user.family }

  before do
    sign_in user
  end

  describe "GET /accounts" do
    context "with no accounts" do
      it "shows empty state" do
        get accounts_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include(I18n.t('accounts.index.empty_state'))
      end
    end

    context "with active accounts" do
      let!(:account1) { create(:account, family: family, name: "Nubank") }
      let!(:account2) { create(:account, family: family, name: "Bradesco") }

      it "lists all active accounts" do
        get accounts_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Nubank")
        expect(response.body).to include("Bradesco")
      end
    end

    context "with archived accounts" do
      let!(:active_account) { create(:account, family: family, name: "Nubank") }
      let!(:archived_account) { create(:account, :archived, family: family, name: "Old Account") }

      it "does not show archived accounts by default" do
        get accounts_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Nubank")
        expect(response.body).not_to include("Old Account")
      end

      it "shows archived accounts when requested" do
        get accounts_path(show_archived: true)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Nubank")
        expect(response.body).to include("Old Account")
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in" do
        get accounts_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /accounts/:id" do
    let(:account) { create(:account, family: family, name: "Nubank") }

    it "shows account details" do
      get account_path(account)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Nubank")
    end

    context "when account belongs to different family" do
      let(:other_user) { create(:user, status: :active) }
      let(:other_account) { create(:account, family: other_user.family) }

      it "redirects with error" do
        get account_path(other_account)
        expect(response).to redirect_to(accounts_path)
        follow_redirect!
        expect(response.body).to include(I18n.t('accounts.not_found'))
      end
    end
  end

  describe "GET /accounts/new" do
    it "renders new account form" do
      get new_account_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t('accounts.new.title'))
    end
  end

  describe "POST /accounts" do
    context "with valid params" do
      let(:valid_params) do
        {
          account: {
            name: "Nubank",
            account_type: "checking",
            initial_balance: "1500,00"
          }
        }
      end

      it "creates a new account" do
        expect {
          post accounts_path, params: valid_params
        }.to change(Account, :count).by(1)
      end

      it "sets correct attributes" do
        post accounts_path, params: valid_params
        account = Account.last

        expect(account.name).to eq("Nubank")
        expect(account.account_type).to eq("checking")
        expect(account.initial_balance_cents).to eq(150000)
        expect(account.family).to eq(family)
      end

      it "sets icon and color automatically" do
        post accounts_path, params: valid_params
        account = Account.last

        expect(account.icon).to eq("🏦")
        expect(account.color).to eq("#2563EB")
      end

      it "redirects to accounts index with success message" do
        post accounts_path, params: valid_params
        expect(response).to redirect_to(accounts_path)
        follow_redirect!
        expect(response.body).to include(I18n.t('accounts.create.success'))
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          account: {
            name: "",
            account_type: "checking",
            initial_balance: "0"
          }
        }
      end

      it "does not create account" do
        expect {
          post accounts_path, params: invalid_params
        }.not_to change(Account, :count)
      end

      it "renders new template with errors" do
        post accounts_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("não pode ficar em branco")
      end
    end

    context "with investment account type" do
      let(:investment_params) do
        {
          account: {
            name: "Tesouro Direto",
            account_type: "investment",
            initial_balance: "10000,00"
          }
        }
      end

      it "sets investment icon and color" do
        post accounts_path, params: investment_params
        account = Account.last

        expect(account.icon).to eq("📈")
        expect(account.color).to eq("#10B981")
      end
    end
  end

  describe "GET /accounts/:id/edit" do
    let(:account) { create(:account, family: family) }

    it "renders edit form" do
      get edit_account_path(account)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t('accounts.edit.title'))
    end
  end

  describe "PATCH /accounts/:id" do
    let(:account) { create(:account, family: family, name: "Old Name", initial_balance_cents: 100000) }

    context "with valid params" do
      let(:update_params) do
        {
          account: {
            name: "New Name",
            initial_balance: "2000,00"
          }
        }
      end

      it "updates the account" do
        patch account_path(account), params: update_params
        account.reload

        expect(account.name).to eq("New Name")
        expect(account.initial_balance_cents).to eq(200000)
      end

      it "redirects with success message" do
        patch account_path(account), params: update_params
        expect(response).to redirect_to(account_path(account))
        follow_redirect!
        expect(response.body).to include(I18n.t('accounts.update.success'))
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          account: {
            name: ""
          }
        }
      end

      it "does not update account" do
        expect {
          patch account_path(account), params: invalid_params
          account.reload
        }.not_to change(account, :name)
      end

      it "renders edit template with errors" do
        patch account_path(account), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "attempting to change account_type" do
      let(:type_change_params) do
        {
          account: {
            account_type: "investment"
          }
        }
      end

      it "does not change account_type (immutable)" do
        original_type = account.account_type
        patch account_path(account), params: type_change_params
        account.reload

        expect(account.account_type).to eq(original_type)
      end
    end
  end

  describe "DELETE /accounts/:id/archive" do
    let(:account) { create(:account, family: family) }

    it "archives the account" do
      delete archive_account_path(account)
      account.reload

      expect(account.archived?).to be true
    end

    it "redirects with success message" do
      delete archive_account_path(account)
      expect(response).to redirect_to(accounts_path)
      follow_redirect!
      expect(response.body).to include(I18n.t('accounts.archive.success'))
    end
  end

  describe "PATCH /accounts/:id/unarchive" do
    let(:account) { create(:account, :archived, family: family) }

    it "unarchives the account" do
      patch unarchive_account_path(account)
      account.reload

      expect(account.archived?).to be false
    end

    it "redirects with success message" do
      patch unarchive_account_path(account)
      expect(response).to redirect_to(accounts_path)
      follow_redirect!
      expect(response.body).to include(I18n.t('accounts.unarchive.success'))
    end
  end
end
