# frozen_string_literal: true

class Admin::DashboardController < AdminController
  def index
    @total_sites = Site.count
    @total_users = User.count
    @total_system_settings = SystemSetting.count
  end
end
