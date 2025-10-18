class UsersFilterService
  def initialize(params = {})
    @params = params
  end

  def call
    users = User.all

    if @params[:name].present?
      users = users.where("name LIKE ?", "%#{@params[:name]}%")
    end

    if @params[:email].present?
      users = users.where("email LIKE ?", "%#{@params[:email]}%")
    end

    if @params[:role].present?
      users = users.where(role: @params[:role])
    end

    users.order(created_at: :desc)
  end
end
