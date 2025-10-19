FactoryBot.define do
  factory :transaction do
    association :account
    association :category
    association :user

    transaction_type { 'expense' }
    amount_cents { 15_000 } # R$ 150.00
    currency { 'BRL' }
    transaction_date { Date.current }
    description { 'Test transaction' }
    is_template { false }

    trait :income do
      transaction_type { 'income' }
    end

    trait :expense do
      transaction_type { 'expense' }
    end

    trait :template do
      is_template { true }
      frequency { 'monthly' }
      start_date { Date.current }
      end_date { nil }
    end

    trait :transfer do
      association :category, factory: :category, name: 'Transferência'
      after(:create) do |transaction|
        # Create linked transaction if not already present
        unless transaction.linked_transaction
          linked = create(:transaction,
                          transaction_type: transaction.income? ? 'expense' : 'income',
                          amount_cents: transaction.amount_cents,
                          transaction_date: transaction.transaction_date,
                          description: transaction.description,
                          category: transaction.category,
                          user: transaction.user)
          transaction.update_column(:linked_transaction_id, linked.id)
          linked.update_column(:linked_transaction_id, transaction.id)
        end
      end
    end

    trait :effectuated do
      effectuated_at { Time.current }
    end

    trait :pending do
      transaction_date { 1.month.from_now }
      effectuated_at { nil }
    end
  end
end
