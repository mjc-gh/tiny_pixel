# frozen_string_literal: true

class WeeklySummaryJob < ApplicationJob
  queue_as :default

  def perform
    return unless TinyPixel.email_delivery_supported?

    # Find all users with at least one site membership
    User.joins(:memberships).distinct.find_each do |user|
      sites = user.sites
      next if sites.empty?

      # Compute stats for each site using the service
      sites_data = sites.map { |site| SiteStatsService.new(site).compute }

      # Send email
      SitesMailer.weekly_summary(user, sites_data).deliver_later
    end
  end
end
