# frozen_string_literal: true

class SitesMailer < ApplicationMailer
  def weekly_summary(user, sites_data)
    @user = user
    @sites_data = sites_data
    mail(to: @user.email, subject: t(".subject"))
  end
end
