class Transaction < ApplicationRecord
  # Enums
  enum :transaction_type, { income: "income", expense: "expense" }
  enum :frequency, {
    monthly: "monthly",
    bimonthly: "bimonthly",
    quarterly: "quarterly",
    semiannual: "semiannual",
    annual: "annual"
  }

  # Money
  monetize :amount_cents

  # Virtual attribute to accept amount in reais (BRL) and convert to cents
  def amount=(value)
    self.amount_cents = (value.to_f * 100).to_i if value.present?
  end

  def amount
    amount_cents / 100.0 if amount_cents
  end

  # Associations
  belongs_to :account
  belongs_to :category
  belongs_to :user
  belongs_to :editor, class_name: "User", optional: true
  belongs_to :parent_transaction, class_name: "Transaction", optional: true
  belongs_to :linked_transaction, class_name: "Transaction", optional: true
  has_many :children, class_name: "Transaction", foreign_key: :parent_transaction_id, dependent: false

  # Scopes - Type scopes
  scope :income_transactions, -> { where(transaction_type: "income") }
  scope :expense_transactions, -> { where(transaction_type: "expense") }

  # Scopes - Template scopes
  scope :templates, -> { where(is_template: true) }
  scope :one_time, -> { where(is_template: false, parent_transaction_id: nil) }
  scope :generated_from_template, -> { where.not(parent_transaction_id: nil) }

  # Scopes - Effectuation scopes (timezone-aware)
  scope :effectuated, lambda {
    tz = Time.find_zone("America/Sao_Paulo")
    where("effectuated_at IS NOT NULL OR transaction_date <= ?", tz.now.to_date)
  }
  scope :pending, lambda {
    tz = Time.find_zone("America/Sao_Paulo")
    where("effectuated_at IS NULL AND transaction_date > ?", tz.now.to_date)
  }

  # Scopes - Transfer scopes
  scope :transfers, -> { joins(:category).where(categories: { name: "Transferência" }) }

  # Scopes - Date scopes
  scope :by_month, lambda { |month_string|
    year, month = month_string.split("-").map(&:to_i)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month
    where(transaction_date: start_date..end_date)
  }
  scope :in_period, ->(start_date, end_date) { where(transaction_date: start_date..end_date) }

  # Scopes - Filtering scope
  scope :apply_filters, lambda { |filters|
    result = all
    result = result.where(transaction_type: filters[:transaction_type_filter]) if filters[:transaction_type_filter].present?
    result = result.where(category_id: filters[:category_id]) if filters[:category_id].present?
    result = result.where(account_id: filters[:account_id]) if filters[:account_id].present?
    result = result.where("description ILIKE ?", "%#{filters[:search]}%") if filters[:search].present?

    if filters[:status] == "effectuated"
      result = result.effectuated
    elsif filters[:status] == "pending"
      result = result.pending
    end

    if filters[:period_start].present? && filters[:period_end].present?
      result = result.in_period(filters[:period_start], filters[:period_end])
    end

    result
  }

  # Validations
  validates :transaction_type, presence: true, inclusion: { in: transaction_types.keys }
  validates :amount_cents, presence: true,
                           numericality: {
                             only_integer: true,
                             greater_than: 0,
                             less_than_or_equal_to: 99_999_999_999
                           }
  validates :transaction_date, presence: true
  validates :description, presence: true, length: { minimum: 3, maximum: 500 }
  validates :currency, presence: true, inclusion: { in: [ "BRL" ] }

  # Template-specific validations
  validates :frequency, presence: true, if: :is_template?
  validates :start_date, presence: true, if: :is_template?
  validates :end_date, comparison: { greater_than: :start_date }, allow_nil: true, if: :is_template?

  # Non-template validations
  validates :frequency, absence: true, unless: :is_template?
  validates :start_date, absence: true, unless: :is_template?
  validates :end_date, absence: true, unless: :is_template?
  validates :parent_transaction_id, absence: true, if: :is_template?

  # Category/Account active validations
  validate :category_not_archived
  validate :account_not_archived

  # Callbacks
  after_save :recalculate_account_balance
  after_destroy :recalculate_account_balance
  after_save :regenerate_future_transactions, if: :saved_change_to_template_attributes?
  before_update :set_editor
  before_update :unlink_from_template_if_manually_edited
  before_destroy :destroy_pending_children_if_template
  before_destroy :destroy_linked_transaction_if_transfer

  # Business methods - Effectuation
  def mark_as_paid!
    return if effectuated?

    update!(effectuated_at: Time.current)
  end

  def unmark_as_paid!
    return unless manually_effectuated? && pending_by_date?

    update!(effectuated_at: nil)
  end

  def effectuated?
    effectuated_at.present? || transaction_date <= Time.current.in_time_zone("America/Sao_Paulo").to_date
  end

  def manually_effectuated?
    effectuated_at.present?
  end

  def pending_by_date?
    transaction_date > Time.current.in_time_zone("America/Sao_Paulo").to_date
  end

  # Business methods - Template operations
  def template?
    is_template?
  end

  def generated?
    parent_transaction_id.present?
  end

  # Business methods - Transfer operations
  def transfer?
    category&.name == "Transferência"
  end

  def transfer_pair?
    linked_transaction_id.present?
  end

  private

  def category_not_archived
    return unless category

    errors.add(:category, "está arquivada") if category.respond_to?(:archived?) && category.archived?
  end

  def account_not_archived
    return unless account

    errors.add(:account, "está arquivada") if account.archived?
  end

  def recalculate_account_balance
    BalanceCalculator.recalculate(account) if account
  end

  def regenerate_future_transactions
    return unless is_template?

    TransactionService.regenerate_from_template(self)
  end

  def saved_change_to_template_attributes?
    is_template? && (
      saved_change_to_amount_cents? ||
      saved_change_to_description? ||
      saved_change_to_category_id? ||
      saved_change_to_frequency? ||
      saved_change_to_start_date? ||
      saved_change_to_end_date?
    )
  end

  def set_editor
    # Using Current if available, otherwise skip
    self.editor_id = Current.user&.id if defined?(Current)
    self.edited_at = Time.current
  end

  def destroy_linked_transaction_if_transfer
    return unless transfer_pair? && linked_transaction

    # Avoid infinite loop by temporarily removing the link before destroying
    linked = linked_transaction
    update_column(:linked_transaction_id, nil)
    linked.destroy if linked.persisted?
  end

  def unlink_from_template_if_manually_edited
    # Only for generated transactions (not templates themselves)
    return if is_template? || parent_transaction_id.nil?

    # Check if any significant attribute changed (using will_save_change for before_update)
    manual_edit = will_save_change_to_amount_cents? ||
                  will_save_change_to_description? ||
                  will_save_change_to_category_id? ||
                  will_save_change_to_transaction_date? ||
                  will_save_change_to_account_id?

    # Unlink from template if manually edited
    self.parent_transaction_id = nil if manual_edit
  end

  def destroy_pending_children_if_template
    return unless is_template?

    # Destroy only pending children (future date, not manually marked as paid)
    # This matches User Story 5 requirement: keep effectuated transactions when template is deleted
    children.pending.where(effectuated_at: nil).destroy_all

    # Nullify parent_transaction_id for remaining children (effectuated and manually marked)
    # This allows the template to be deleted without foreign key constraint violations
    children.update_all(parent_transaction_id: nil)
  end
end
