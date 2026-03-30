# frozen_string_literal: true

module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :user_signed_in?
  end

  def current_user
    Current.user ||= authenticate_user_from_session
  end

  def user_signed_in?
    current_user.present?
  end

  def authenticate_user!
    redirect_to login_path, alert: "You must be logged in to access this page." unless user_signed_in?
  end

  private

  def authenticate_user_from_session
    User.find_by(id: session[:user_id]) if session[:user_id]
  end
end
