class Account < ApplicationRecord
  # Associations
  belongs_to :family

  # Enums
  enum :account_type, { checking: 0, investment: 1 }

  # Validations
  validates :name, presence: true, length: { maximum: 50 }
  validates :account_type, presence: true
  validates :initial_balance_cents, presence: true, numericality: { only_integer: true }
  validates :icon, presence: true
  validates :color, presence: true, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: "must be valid hex color" }
  validates :family_id, presence: true

  # Money-rails integration
  monetize :initial_balance_cents, with_model_currency: :currency

  # Scopes
  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :ordered_by_creation, -> { order(created_at: :desc) }

  # Callbacks
  before_validation :set_icon_and_color, on: :create

  # Instance methods
  def current_balance
    # For now, return initial balance (transactions will be implemented in future phase)
    Money.new(initial_balance_cents, "BRL")
  end

  def positive_balance?
    current_balance.positive?
  end

  def archive!
    update(archived_at: Time.current)
  end

  def unarchive!
    update(archived_at: nil)
  end

  def archived?
    archived_at.present?
  end

  def type_with_icon
    "#{icon} #{account_type.humanize}"
  end

  def currency
    "BRL"
  end

  private

  def set_icon_and_color
    case account_type
    when "checking"
      self.icon ||= "🏦"
      self.color ||= "#2563EB"
    when "investment"
      self.icon ||= "📈"
      self.color ||= "#10B981"
    end
  end
end
