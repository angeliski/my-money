class UsersController < ApplicationController
  before_action :set_user, only: %i[ show edit update destroy ]
  before_action :authenticate_user!
  before_action :authorize_admin_or_supervisor!, except: [ :validate_operation_code, :no_terminal ]

  # GET /users or /users.json
  def index
    begin
      filtered_users = UsersFilterService.new(filter_params).call
      items_per_page = [ (params[:per_page] || 10).to_i, 100 ].min  # Max 100 items per page
      items_per_page = 10 if items_per_page <= 0  # Minimum 10 items per page


      @pagy, @users = pagy(filtered_users, limit: items_per_page)
    rescue Pagy::OverflowError
      # Redirect to last page if page number is too high
      redirect_to users_path(filter_params.merge(page: 1))
      nil
    end
  end

  # GET /users/1 or /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users or /users.json
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.invite!
        format.html { redirect_to @user, notice: "User was successfully created." }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1 or /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: "User was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1 or /users/1.json
  def destroy
    @user.destroy!

    respond_to do |format|
      format.html { redirect_to users_path, notice: "User was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  # POST /users/validate_operation_code
  def validate_operation_code
    operation_code = params[:operation_code]

    user = User.find_by(operation_code: operation_code, status: :active, role: [ :admin, :operator_supervisor ])

    render json: { valid: user.present? }
  end

  # GET /no_terminal
  def no_terminal
    # Se o usuário tem um terminal, redireciona para o terminal correto
    if current_user.has_assigned_terminal?
      redirect_to_user_terminal
      nil
    else
      render layout: "terminal"
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(:name, :email, :role)
    end

    def filter_params
      params.permit(:name, :email, :role, :per_page, :page)
    end
end
