class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Pagy::Backend
  include RoleAuthorization


  layout :layout_by_resource

  private

  def layout_by_resource
    if devise_controller? && resource_name == :user
      "auth"
    else
      "application"
    end
  end
end
