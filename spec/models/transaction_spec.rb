require "rails_helper"

RSpec.describe Transaction, type: :model do
  describe "associations" do
    it { should belong_to(:account) }
    it { should belong_to(:category) }
    it { should belong_to(:user) }
    it { should belong_to(:editor).class_name("User").optional }
    it { should belong_to(:parent_transaction).class_name("Transaction").optional }
    it { should belong_to(:linked_transaction).class_name("Transaction").optional }
    it { should have_many(:children).class_name("Transaction") }
  end

  describe "validations" do
    it { should validate_presence_of(:transaction_type) }
    it { should validate_presence_of(:amount_cents) }
    it { should validate_presence_of(:transaction_date) }
    it { should validate_presence_of(:description) }
    it { should validate_length_of(:description).is_at_least(3).is_at_most(500) }

    it "validates amount_cents is greater than 0" do
      transaction = build(:transaction, amount_cents: 0)
      expect(transaction).not_to be_valid
      expect(transaction.errors[:amount_cents]).to be_present
    end

    context "when is_template is true" do
      it "requires frequency" do
        transaction = build(:transaction, is_template: true, start_date: Date.current)
        transaction.frequency = nil
        expect(transaction).not_to be_valid
        expect(transaction.errors[:frequency]).to be_present
      end

      it "automatically sets start_date from transaction_date if not provided" do
        transaction = build(:transaction, is_template: true, frequency: "monthly", transaction_date: Date.current)
        transaction.start_date = nil
        expect(transaction).to be_valid
        transaction.valid? # Trigger callbacks
        expect(transaction.start_date).to eq(Date.current)
      end
    end

    context "when is_template is false" do
      it "does not allow frequency" do
        transaction = build(:transaction, is_template: false, frequency: "monthly")
        expect(transaction).not_to be_valid
      end

      it "does not allow start_date" do
        transaction = build(:transaction, is_template: false, start_date: Date.current)
        expect(transaction).not_to be_valid
      end
    end
  end

  describe "scopes" do
    let(:account) { create(:account) }
    let!(:income) { create(:transaction, :income, account: account) }
    let!(:expense) { create(:transaction, :expense, account: account) }
    let!(:template) { create(:transaction, :template, account: account) }

    describe ".income_transactions" do
      it "returns only income transactions" do
        expect(Transaction.income_transactions).to include(income)
        expect(Transaction.income_transactions).not_to include(expense)
      end
    end

    describe ".expense_transactions" do
      it "returns only expense transactions" do
        expect(Transaction.expense_transactions).to include(expense)
        expect(Transaction.expense_transactions).not_to include(income)
      end
    end

    describe ".templates" do
      it "returns only template transactions" do
        expect(Transaction.templates).to include(template)
        expect(Transaction.templates).not_to include(income, expense)
      end
    end

    describe ".one_time" do
      it "returns only one-time transactions" do
        expect(Transaction.one_time).to include(income, expense)
        expect(Transaction.one_time).not_to include(template)
      end
    end
  end

  describe "business methods" do
    describe "#effectuated?" do
      it "returns true if effectuated_at is set" do
        transaction = build(:transaction, effectuated_at: Time.current)
        expect(transaction.effectuated?).to be true
      end

      it "returns true if transaction_date is in the past" do
        transaction = build(:transaction, transaction_date: 1.day.ago)
        expect(transaction.effectuated?).to be true
      end

      it "returns false if transaction_date is in the future and no effectuated_at" do
        transaction = build(:transaction, transaction_date: 1.day.from_now, effectuated_at: nil)
        expect(transaction.effectuated?).to be false
      end
    end

    describe "#transfer?" do
      it "returns true for transactions with Transferência category" do
        transfer_category = create(:category, name: "Transferência")
        transaction = build(:transaction, category: transfer_category)
        expect(transaction.transfer?).to be true
      end

      it "returns false for normal transactions" do
        transaction = build(:transaction)
        expect(transaction.transfer?).to be false
      end
    end
  end

  describe "callbacks" do
    it "recalculates account balance after save" do
      account = create(:account)
      expect(BalanceCalculator).to receive(:recalculate).with(account)
      create(:transaction, account: account)
    end

    it "recalculates account balance after destroy" do
      transaction = create(:transaction)
      account = transaction.account
      expect(BalanceCalculator).to receive(:recalculate).with(account)
      transaction.destroy
    end

    describe "unlinking from template when manually edited" do
      let(:template) { create(:transaction, :template) }
      let(:generated_transaction) do
        create(:transaction,
               parent_transaction: template,
               amount_cents: template.amount_cents,
               description: template.description,
               category: template.category,
               account: template.account,
               transaction_date: 1.month.from_now)
      end

      it "unlinks generated transaction when amount is edited" do
        expect(generated_transaction.parent_transaction_id).to eq(template.id)
        generated_transaction.update(amount_cents: 50_000)
        expect(generated_transaction.reload.parent_transaction_id).to be_nil
      end

      it "unlinks generated transaction when description is edited" do
        expect(generated_transaction.parent_transaction_id).to eq(template.id)
        generated_transaction.update(description: "Nova descrição")
        expect(generated_transaction.reload.parent_transaction_id).to be_nil
      end

      it "unlinks generated transaction when category is edited" do
        new_category = create(:category)
        expect(generated_transaction.parent_transaction_id).to eq(template.id)
        generated_transaction.update(category: new_category)
        expect(generated_transaction.reload.parent_transaction_id).to be_nil
      end

      it "does not unlink when non-significant attributes are updated" do
        expect(generated_transaction.parent_transaction_id).to eq(template.id)
        generated_transaction.update(effectuated_at: Time.current)
        expect(generated_transaction.reload.parent_transaction_id).to eq(template.id)
      end

      it "does not affect templates themselves when edited" do
        expect(template.parent_transaction_id).to be_nil
        template.update(amount_cents: 60_000)
        expect(template.reload.parent_transaction_id).to be_nil
      end
    end

    describe "template deletion" do
      let(:template) { create(:transaction, :template) }
      let!(:pending_child) do
        create(:transaction,
               parent_transaction: template,
               transaction_date: 1.month.from_now,
               effectuated_at: nil,
               account: template.account,
               category: template.category)
      end
      let!(:effectuated_child) do
        create(:transaction,
               parent_transaction: template,
               transaction_date: 1.day.ago,
               effectuated_at: nil,
               account: template.account,
               category: template.category)
      end
      let!(:manually_paid_child) do
        create(:transaction,
               parent_transaction: template,
               transaction_date: 1.month.from_now,
               effectuated_at: Time.current,
               account: template.account,
               category: template.category)
      end

      it "destroys only pending non-manually-effectuated children when template is deleted" do
        pending_id = pending_child.id
        effectuated_id = effectuated_child.id
        manually_paid_id = manually_paid_child.id

        template.destroy

        expect(Transaction.exists?(pending_id)).to be false
        expect(Transaction.exists?(effectuated_id)).to be true
        expect(Transaction.exists?(manually_paid_id)).to be true
      end

      it "keeps effectuated transactions when template is deleted" do
        template.destroy
        expect(effectuated_child.reload).to be_present
        expect(effectuated_child.parent_transaction_id).to be_nil
      end

      it "keeps manually marked transactions when template is deleted" do
        template.destroy
        expect(manually_paid_child.reload).to be_present
        expect(manually_paid_child.parent_transaction_id).to be_nil
      end
    end
  end
end
