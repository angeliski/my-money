FactoryBot.define do
  factory :account do
    name { "Test Account #{rand(1000)}" }
    account_type { :checking }
    initial_balance_cents { rand(-100_000..500_000) }
    icon { '🏦' }
    color { '#2563EB' }
    association :family

    trait :checking do
      account_type { :checking }
      icon { '🏦' }
      color { '#2563EB' }
    end

    trait :investment do
      account_type { :investment }
      icon { '📈' }
      color { '#10B981' }
    end

    trait :archived do
      archived_at { 1.month.ago }
    end

    trait :negative_balance do
      initial_balance_cents { -50_000 }
    end

    trait :positive_balance do
      initial_balance_cents { 150_000 }
    end
  end
end
