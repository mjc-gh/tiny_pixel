# frozen_string_literal: true

class StatsRetentionJob < ApplicationJob
  queue_as :default

  def perform
    Site.find_each do |site|
      cutoff = site.stats_retention_cutoff

      hourly_deleted = HourlyPageStat.for_site(site.id).older_than(cutoff).delete_all
      daily_deleted = DailyPageStat.for_site(site.id).older_than(cutoff).delete_all
      weekly_deleted = WeeklyPageStat.for_site(site.id).older_than(cutoff).delete_all

      total_deleted = hourly_deleted + daily_deleted + weekly_deleted

      Rails.logger.info("StatsRetentionJob: Deleted #{total_deleted} stat records for site #{site.id}")
    end
  end
end
