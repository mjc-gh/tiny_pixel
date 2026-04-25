# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :require_password_reset!, if: :user_signed_in?, unless: :skip_password_reset_check?

  private

  def authorize_site_admin!
    head :forbidden unless current_user.admin_for?(@site)
  end

  def set_site
    @site = current_user.sites.find(params[:site_id])
  end

  def require_password_reset!
    return unless current_user.password_reset_required?

    redirect_to edit_users_password_reset_path
  end

  def skip_password_reset_check?
    controller_path == "users/password_resets" || revise_auth_controller?
  end

  def revise_auth_controller?
    controller_path.start_with?("revise_auth")
  end
end
