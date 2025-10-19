# Service to handle recurring transaction generation and template management
class TransactionService
  def self.regenerate_from_template(template)
    return unless template.is_template?

    # Delete existing pending non-manually-effectuated transactions
    template.children.pending.where(effectuated_at: nil).destroy_all

    # Calculate dates
    start_date = template.start_date
    end_date = template.end_date || 12.months.from_now.to_date
    dates = calculate_recurrence_dates(start_date, end_date, template.frequency)

    # Generate new transactions
    dates.each do |date|
      template.children.create!(
        transaction_type: template.transaction_type,
        amount_cents: template.amount_cents,
        transaction_date: date,
        description: template.description,
        category_id: template.category_id,
        account_id: template.account_id,
        user_id: template.user_id,
        currency: template.currency,
        is_template: false
      )
    end
  end

  def self.calculate_recurrence_dates(start_date, end_date, frequency)
    dates = []
    current = start_date
    max_date = [ end_date, 12.months.from_now.to_date ].min

    while current <= max_date
      dates << current
      current = case frequency
      when "monthly" then current + 1.month
      when "bimonthly" then current + 2.months
      when "quarterly" then current + 3.months
      when "semiannual" then current + 6.months
      when "annual" then current + 1.year
      else
                  break # Invalid frequency
      end
    end

    dates
  end
  private_class_method :calculate_recurrence_dates
end
