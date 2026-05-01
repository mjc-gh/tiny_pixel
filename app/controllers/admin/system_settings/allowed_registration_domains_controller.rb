# frozen_string_literal: true

class Admin::SystemSettings::AllowedRegistrationDomainsController < AdminController
  def update
    domains = params[:domains]&.split("\n") || []
    domains = domains.map(&:strip).reject(&:blank?)

    SystemSetting.transaction do
      SystemSetting.where(name: :allowed_registration_domain).delete_all

      domains.each do |domain|
        SystemSetting.create!(name: :allowed_registration_domain, value: domain)
      end
    end

    redirect_to admin_system_settings_path, notice: t("admin.system_settings.allowed_registration_domains.update.success")
  end
end
