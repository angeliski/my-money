class Family < ApplicationRecord
  has_many :users, dependent: :restrict_with_error
  has_many :accounts, dependent: :restrict_with_error
end
