# frozen_string_literal: true

namespace :tiny_pixel do
  desc "Ouput auto-genated system admin password"
  task system_admin_password: :environment do
    password = AdminController.secret_password

    if ENV["TP_DOMAIN_NAME"].present?
      include Rails.application.routes.url_helpers

      Rails.application.routes.default_url_options = {
        host: ENV["TP_DOMAIN_NAME"]
      }

      puts "Open the link below to login to your admin panel:"
      puts admin_url host: ENV["TP_DOMAIN_NAME"], user: "tiny_pixel", password:
    else
      puts "Use the following username and password to login to the system admin site (/admin):"
      puts "  - username: tiny_pixel"
      puts "  - password: #{password}"
    end
  end
end
