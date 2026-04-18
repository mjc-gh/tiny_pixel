# frozen_string_literal: true

class Users::RegistrationsController < ReviseAuth::RegistrationsController
  prepend_before_action :redirect_unless_registration_allowed

  private

  def redirect_unless_registration_allowed
    return if Rails.application.config.runtime_settings.allow_registration

    redirect_to login_url, alert: t("users.registrations.not_allowed")
  end
end
