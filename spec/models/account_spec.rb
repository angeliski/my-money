require 'rails_helper'

RSpec.describe Account, type: :model do
  describe 'associations' do
    it { should belong_to(:family) }
  end

  describe 'validations' do
    subject { build(:account) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(50) }
    it { should validate_presence_of(:account_type) }
    it { should validate_presence_of(:initial_balance_cents) }
    it { should validate_numericality_of(:initial_balance_cents).only_integer }
    it { should validate_presence_of(:family_id) }

    # Icon and color presence is enforced by:
    # 1. Database NOT NULL constraint
    # 2. before_validation callback (tested in callbacks section)
    # So explicit presence validation tests are not needed here

    it 'validates color format' do
      account = create(:account)
      account.color = 'invalid'
      expect(account).not_to be_valid
      expect(account.errors[:color]).to include('must be valid hex color')
    end

    it 'accepts valid hex color' do
      account = create(:account, color: '#2563EB')
      expect(account).to be_valid
    end
  end

  describe 'enums' do
    it { should define_enum_for(:account_type).with_values(checking: 0, investment: 1) }
  end

  describe 'scopes' do
    let(:family) { create(:family) }
    let!(:active_account) { create(:account, family: family, archived_at: nil) }
    let!(:archived_account) { create(:account, family: family, archived_at: 1.day.ago) }

    it 'returns only active accounts' do
      expect(Account.active).to include(active_account)
      expect(Account.active).not_to include(archived_account)
    end

    it 'returns only archived accounts' do
      expect(Account.archived).to include(archived_account)
      expect(Account.archived).not_to include(active_account)
    end

    it 'orders by creation date descending' do
      # Create older account first, wait a bit, then create newer
      older_account = create(:account, family: family)
      sleep 0.01  # Small delay to ensure different timestamps
      newer_account = create(:account, family: family)

      accounts = Account.ordered_by_creation.where(family: family, archived_at: nil).to_a
      expect(accounts.first.id).to eq(newer_account.id)
    end
  end

  describe 'callbacks' do
    context 'before_validation on create' do
      it 'sets icon and color for checking account' do
        account = build(:account, account_type: :checking, icon: nil, color: nil)
        account.valid?

        expect(account.icon).to eq('🏦')
        expect(account.color).to eq('#2563EB')
      end

      it 'sets icon and color for investment account' do
        account = build(:account, account_type: :investment, icon: nil, color: nil)
        account.valid?

        expect(account.icon).to eq('📈')
        expect(account.color).to eq('#10B981')
      end

      it 'does not override existing icon and color' do
        account = build(:account, account_type: :checking, icon: '💰', color: '#FF0000')
        account.valid?

        expect(account.icon).to eq('💰')
        expect(account.color).to eq('#FF0000')
      end
    end
  end

  describe '#current_balance' do
    let(:account) { create(:account, initial_balance_cents: 150_000) }

    it 'returns Money object' do
      expect(account.current_balance).to be_a(Money)
    end

    it 'returns initial balance in BRL' do
      expect(account.current_balance.cents).to eq(150_000)
      expect(account.current_balance.currency.iso_code).to eq('BRL')
    end
  end

  describe '#positive_balance?' do
    it 'returns true for positive balance' do
      account = create(:account, initial_balance_cents: 100_000)
      expect(account.positive_balance?).to be true
    end

    it 'returns false for negative balance' do
      account = create(:account, initial_balance_cents: -50_000)
      expect(account.positive_balance?).to be false
    end

    it 'returns false for zero balance' do
      account = create(:account, initial_balance_cents: 0)
      expect(account.positive_balance?).to be false
    end
  end

  describe '#archive!' do
    let(:account) { create(:account, archived_at: nil) }

    it 'sets archived_at timestamp' do
      expect { account.archive! }.to change { account.archived_at }.from(nil)
    end

    it 'persists the change' do
      account.archive!
      account.reload
      expect(account.archived_at).not_to be_nil
    end
  end

  describe '#unarchive!' do
    let(:account) { create(:account, archived_at: 1.day.ago) }

    it 'clears archived_at timestamp' do
      expect { account.unarchive! }.to change { account.archived_at }.to(nil)
    end

    it 'persists the change' do
      account.unarchive!
      account.reload
      expect(account.archived_at).to be_nil
    end
  end

  describe '#archived?' do
    it 'returns true when archived_at is set' do
      account = create(:account, archived_at: 1.day.ago)
      expect(account.archived?).to be true
    end

    it 'returns false when archived_at is nil' do
      account = create(:account, archived_at: nil)
      expect(account.archived?).to be false
    end
  end

  describe '#type_with_icon' do
    it 'returns icon with humanized account type for checking' do
      account = build(:account, :checking)
      expect(account.type_with_icon).to eq('🏦 Checking')
    end

    it 'returns icon with humanized account type for investment' do
      account = build(:account, :investment)
      expect(account.type_with_icon).to eq('📈 Investment')
    end
  end

  describe 'factory traits' do
    it 'creates checking account with correct attributes' do
      account = create(:account, :checking)
      expect(account.account_type).to eq('checking')
      expect(account.icon).to eq('🏦')
      expect(account.color).to eq('#2563EB')
    end

    it 'creates investment account with correct attributes' do
      account = create(:account, :investment)
      expect(account.account_type).to eq('investment')
      expect(account.icon).to eq('📈')
      expect(account.color).to eq('#10B981')
    end

    it 'creates archived account' do
      account = create(:account, :archived)
      expect(account.archived?).to be true
    end

    it 'creates account with negative balance' do
      account = create(:account, :negative_balance)
      expect(account.initial_balance_cents).to be < 0
    end

    it 'creates account with positive balance' do
      account = create(:account, :positive_balance)
      expect(account.initial_balance_cents).to be > 0
    end
  end
end
