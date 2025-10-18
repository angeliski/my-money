module RoleAuthorization
  extend ActiveSupport::Concern

  included do
    rescue_from UnauthorizedAccess, with: :handle_unauthorized_access
  end

  class UnauthorizedAccess < StandardError; end

  private

  def authorize_admin!
    raise UnauthorizedAccess unless current_user&.admin_role?
  end

  def authorize_admin_or_supervisor!
    raise UnauthorizedAccess unless current_user&.admin_role? || current_user&.operator_supervisor_role?
  end

  def authorize_cash_operator!
    raise UnauthorizedAccess unless current_user&.admin_role? || current_user&.cash_operator_role?
  end

  def authorize_sales_operator!
    raise UnauthorizedAccess unless current_user&.admin_role? || current_user&.sales_operator_role?
  end

  def authorize_prep_operator!
    raise UnauthorizedAccess unless current_user&.admin_role? || current_user&.prep_operator_role?
  end

  def authorize_terminal_access!(terminal)
    return true if current_user&.admin_role?

    unless current_user&.terminals&.include?(terminal)
      raise UnauthorizedAccess
    end
  end

  # Verifica se o usuário tem permissão para acessar um terminal específico
  # Redireciona para o terminal correto se necessário
  def check_terminal_access!(terminal)
    return true if current_user&.admin_role?

    # Se o usuário não tem terminal associado, redireciona para página de erro
    unless current_user&.has_assigned_terminal?
      redirect_to no_terminal_path
      return false
    end

    # Se está tentando acessar um terminal que não é o dele, redireciona
    unless current_user.can_access_terminal?(terminal)
      redirect_to_user_terminal
      return false
    end

    true
  end

  # Redireciona o usuário para o terminal correto baseado no tipo
  def redirect_to_user_terminal
    terminal = current_user.assigned_terminal
    path = case terminal.operation_type
    when "cash_point", "cash_sales_point", "sales_point"
      terminal_access_path(terminal_id: terminal.id)
    when "queue_point"
      queue_terminals_path
    else
      root_path
    end

    flash[:alert] = "Você não tem permissão para acessar este terminal. Redirecionado para seu terminal."
    redirect_to path
  end

  def handle_unauthorized_access
    respond_to do |format|
      format.html do
        flash[:alert] = "Você não tem permissão para acessar esta página."
        redirect_to root_path
      end
      format.json do
        render json: { error: "Acesso não autorizado" }, status: :forbidden
      end
    end
  end
end
