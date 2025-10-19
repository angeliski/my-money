class Category < ApplicationRecord
  # Associations
  has_many :transactions, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true, uniqueness: true
end
