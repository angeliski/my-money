module TransactionsHelper
  def format_day_header(date)
    today = Date.current
    yesterday = today - 1.day

    if date == today
      "Hoje • #{date.day}"
    elsif date == yesterday
      "Ontem • #{date.day}"
    else
      I18n.l(date, format: '%d de %B de %Y').capitalize + " • #{transactions_on_date(date).count}"
    end
  end

  def transactions_on_date(date)
    # This will be overridden in the view context
    []
  end

  def format_transaction_amount(transaction)
    color = transaction.income? ? 'text-green-600' : 'text-red-600'
    sign = transaction.income? ? '+' : '-'

    content_tag(:span, class: color) do
      "#{sign} #{number_to_currency(transaction.amount_cents / 100.0, unit: 'R$ ')}"
    end
  end

  def group_transactions_by_day(transactions)
    transactions.group_by(&:transaction_date).sort.reverse.to_h
  end
end
