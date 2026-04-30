# frozen_string_literal: true

require "test_helper"

class StatsRetentionJobTest < ActiveJob::TestCase
  test "#perform deletes expired hourly stats" do
    site = sites(:my_blog)
    cutoff_time = site.stats_retention_cutoff

    old_hourly = create_hourly_stat(site, hostname: "old.com", time_bucket: cutoff_time - 1.day)
    recent_hourly = create_hourly_stat(site, hostname: "recent.com", time_bucket: cutoff_time + 1.day)

    StatsRetentionJob.new.perform

    assert_not HourlyPageStat.exists?(old_hourly.id)
    assert HourlyPageStat.exists?(recent_hourly.id)
  end

  test "#perform deletes expired daily stats" do
    site = sites(:my_blog)
    cutoff_time = site.stats_retention_cutoff

    old_daily = create_daily_stat(site, hostname: "old.com", date: (cutoff_time - 1.day).to_date)
    recent_daily = create_daily_stat(site, hostname: "recent.com", date: (cutoff_time + 1.day).to_date)

    StatsRetentionJob.new.perform

    assert_not DailyPageStat.exists?(old_daily.id)
    assert DailyPageStat.exists?(recent_daily.id)
  end

  test "#perform deletes expired weekly stats" do
    site = sites(:my_blog)
    cutoff_time = site.stats_retention_cutoff

    old_weekly = create_weekly_stat(site, hostname: "old.com", week_start: (cutoff_time - 10.days).to_date)
    recent_weekly = create_weekly_stat(site, hostname: "recent.com", week_start: (cutoff_time + 10.days).to_date)

    StatsRetentionJob.new.perform

    assert_not WeeklyPageStat.exists?(old_weekly.id)
    assert WeeklyPageStat.exists?(recent_weekly.id)
  end

  test "#perform iterates through all sites" do
    site_one = sites(:my_blog)
    site_two = Site.create!(name: "Second Site", salt: "placeholder")

    cutoff_one = site_one.stats_retention_cutoff
    cutoff_two = site_two.stats_retention_cutoff

    old_hourly_one = create_hourly_stat(site_one, time_bucket: cutoff_one - 1.day)
    old_hourly_two = create_hourly_stat(site_two, time_bucket: cutoff_two - 1.day)

    StatsRetentionJob.new.perform

    assert_not HourlyPageStat.exists?(old_hourly_one.id)
    assert_not HourlyPageStat.exists?(old_hourly_two.id)
  end

  test "#perform respects individual site retention settings" do
    site_one = sites(:my_blog)
    site_one.update(stats_retention_duration: 30, stats_retention_unit: :days)

    site_two = Site.create!(name: "Site Long Retention", salt: "placeholder")
    site_two.update(stats_retention_duration: 2, stats_retention_unit: :years)

    time_40_days_ago = 40.days.ago
    time_700_days_ago = 700.days.ago

    stat_one_to_delete = create_hourly_stat(site_one, time_bucket: time_40_days_ago)
    stat_two_to_keep = create_hourly_stat(site_two, time_bucket: time_700_days_ago)

    StatsRetentionJob.new.perform

    assert_not HourlyPageStat.exists?(stat_one_to_delete.id)
    assert HourlyPageStat.exists?(stat_two_to_keep.id)
  end

  test "#perform logs deletion counts" do
    site = sites(:my_blog)
    cutoff_time = site.stats_retention_cutoff

    create_hourly_stat(site, time_bucket: cutoff_time - 1.day)
    create_hourly_stat(site, time_bucket: cutoff_time - 1.day)

    # Just verify job runs without raising
    logger_mock = Minitest::Mock.new
    logger_mock.expect :info, nil, [String]
    logger_mock.expect :info, nil, [String]

    Rails.stub :logger, logger_mock do
      StatsRetentionJob.new.perform
    end

    assert_mock logger_mock
  end
end
