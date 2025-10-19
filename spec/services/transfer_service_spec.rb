require "rails_helper"

RSpec.describe TransferService do
  let(:user) { create(:user) }
  let(:from_account) { create(:account, family: user.family) }
  let(:to_account) { create(:account, family: user.family) }
  let!(:transfer_category) { create(:category, name: "Transferência") }

  describe ".create_transfer" do
    let(:valid_params) do
      {
        from_account: from_account,
        to_account: to_account,
        amount_cents: 100_000,
        transaction_date: Date.current,
        description: "Transferência teste",
        user: user
      }
    end

    it "creates two linked transactions" do
      expect {
        TransferService.create_transfer(**valid_params)
      }.to change(Transaction, :count).by(2)
    end

    it "creates an expense in the source account" do
      expense, _income = TransferService.create_transfer(**valid_params)

      expect(expense.account).to eq(from_account)
      expect(expense.transaction_type).to eq("expense")
      expect(expense.amount_cents).to eq(100_000)
      expect(expense.category).to eq(transfer_category)
    end

    it "creates an income in the destination account" do
      _expense, income = TransferService.create_transfer(**valid_params)

      expect(income.account).to eq(to_account)
      expect(income.transaction_type).to eq("income")
      expect(income.amount_cents).to eq(100_000)
      expect(income.category).to eq(transfer_category)
    end

    it "links the two transactions" do
      expense, income = TransferService.create_transfer(**valid_params)

      expect(expense.linked_transaction).to eq(income)
      expect(income.linked_transaction).to eq(expense)
    end

    context "with invalid data" do
      it "raises error if from_account equals to_account" do
        params = valid_params.merge(to_account: from_account)

        expect {
          TransferService.create_transfer(**params)
        }.to raise_error(ArgumentError, "De e Para devem ser contas diferentes")
      end

      it "raises error if from_account is archived" do
        from_account.update(archived_at: Time.current)

        expect {
          TransferService.create_transfer(**valid_params)
        }.to raise_error(ArgumentError, "Conta de origem não encontrada ou arquivada")
      end

      it "raises error if to_account is archived" do
        to_account.update(archived_at: Time.current)

        expect {
          TransferService.create_transfer(**valid_params)
        }.to raise_error(ArgumentError, "Conta de destino não encontrada ou arquivada")
      end
    end
  end
end
