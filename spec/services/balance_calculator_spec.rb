require "rails_helper"

RSpec.describe BalanceCalculator do
  let(:account) { create(:account, initial_balance_cents: 100_000) } # R$ 1.000,00
  let(:transfer_category) { create(:category, name: "Transferência") }
  let(:regular_category) { create(:category, name: "Alimentação") }

  describe ".recalculate" do
    context "with regular transactions" do
      before do
        create(:transaction, :income, account: account, category: regular_category, amount_cents: 50_000)
        create(:transaction, :expense, account: account, category: regular_category, amount_cents: 30_000)
      end

      it "calculates balance correctly" do
        BalanceCalculator.recalculate(account)
        account.reload

        # 100_000 (initial) + 50_000 (income) - 30_000 (expense) = 120_000
        expect(account.balance_cents).to eq(120_000)
      end
    end

    context "with transfer transactions" do
      before do
        # Regular income/expense
        create(:transaction, :income, account: account, category: regular_category, amount_cents: 50_000)
        create(:transaction, :expense, account: account, category: regular_category, amount_cents: 30_000)

        # Transfers (should affect balance but not count in income/expense totals)
        create(:transaction, account: account, transaction_type: "income", category: transfer_category, amount_cents: 20_000)
        create(:transaction, account: account, transaction_type: "expense", category: transfer_category, amount_cents: 10_000)
      end

      it "includes transfers in balance calculation" do
        BalanceCalculator.recalculate(account)
        account.reload

        # 100_000 (initial) + 50_000 (income) - 30_000 (expense) + 20_000 (transfer in) - 10_000 (transfer out) = 130_000
        expect(account.balance_cents).to eq(130_000)
      end
    end

    context "with nil account" do
      it "does not raise error" do
        expect { BalanceCalculator.recalculate(nil) }.not_to raise_error
      end
    end

    context "with no transactions" do
      it "sets balance to initial balance" do
        BalanceCalculator.recalculate(account)
        account.reload

        expect(account.balance_cents).to eq(100_000)
      end
    end
  end
end
