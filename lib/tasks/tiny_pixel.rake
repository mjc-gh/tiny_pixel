# frozen_string_literal: true

namespace :tiny_pixel do
  desc "Ouput auto-genated system admin password"
  task system_admin_password: :environment do
    puts "Use the following password to login to the system admin site (/admin):"
    puts AdminController.secret_password[0..64]
  end
end
