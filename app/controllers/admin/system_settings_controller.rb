# frozen_string_literal: true

class Admin::SystemSettingsController < AdminController
  def show
    @allowed_registration_domains = SystemSetting
      .where(name: :allowed_registration_domain)
      .pluck(:value)
      .join("\n")
  end
end
