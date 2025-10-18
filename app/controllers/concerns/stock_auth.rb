module StockAuth
  extend ActiveSupport::Concern

  included do
    before_action :check_stock_permissions
  end

  private

  def check_stock_permissions
    return true if current_user&.admin?

    case controller_name
    when "stocks"
      check_terminal_stock_permissions
    when "stock_movements"
      check_movement_permissions
    when "stock_alerts"
      check_alert_permissions
    else
      true
    end
  end

  def check_terminal_stock_permissions
    return false unless current_terminal_user || current_user

    case action_name
    when "index", "show"
      # All authenticated terminal users can view stock
      true
    when "transfer", "process_transfer"
      # Only specific roles can transfer
      can_transfer_stock?
    else
      false
    end
  end

  def check_movement_permissions
    # Only admins and managers can view movements
    current_user&.admin? || current_user&.manager?
  end

  def check_alert_permissions
    # Only admins and stockists can manage alerts
    current_user&.admin? || current_user&.stockist?
  end

  def can_transfer_stock?
    return true if current_user&.admin?
    return true if current_user&.stockist?
    return true if current_terminal_user&.terminal&.central_cashier?

    false
  end

  def can_adjust_stock?
    current_user&.admin? || current_user&.stockist?
  end

  def can_view_audit_trail?
    current_user&.admin? || current_user&.manager?
  end
end
