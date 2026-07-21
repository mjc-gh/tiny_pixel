# frozen_string_literal: true

require "test_helper"

class SiteStatsServiceTest < ActiveSupport::TestCase
  setup do
    @site = Site.create!(name: "Test Site")
  end

  # Test granularity selection logic
  test "selects hourly granularity for sites 0-1 day old" do
    site = Site.create!(name: "New Site", created_at: Time.current)
    service = SiteStatsService.new(site)

    result = service.compute
    assert_equal :hourly, result[:granularity]
  end

  test "selects daily granularity for sites 2-14 days old" do
    site = Site.create!(name: "Medium Site", created_at: 7.days.ago)
    service = SiteStatsService.new(site)

    result = service.compute
    assert_equal :daily, result[:granularity]
  end

  test "selects weekly granularity for sites older than 14 days" do
    site = Site.create!(name: "Old Site", created_at: 30.days.ago)
    service = SiteStatsService.new(site)

    result = service.compute
    assert_equal :weekly, result[:granularity]
  end

  # Edge cases for granularity selection
  test "selects hourly granularity for exactly 1 day old site" do
    site = Site.create!(name: "One Day Old", created_at: 24.hours.ago)
    service = SiteStatsService.new(site)

    result = service.compute
    assert_equal :hourly, result[:granularity]
  end

  test "selects daily granularity for exactly 14 days old site" do
    site = Site.create!(name: "Two Weeks Old", created_at: 14.days.ago)
    service = SiteStatsService.new(site)

    result = service.compute
    assert_equal :daily, result[:granularity]
  end

  # Test hourly stats computation
  test "computes hourly stats correctly for new sites" do
    site = Site.create!(name: "New Site", created_at: Time.current)

    # Create hourly stats for last 24 hours
    now = Time.current
    (0..23).each do |hour|
      time_bucket = (now - (23 - hour).hours).beginning_of_hour
      HourlyPageStat.create!(
        site_id: site.id,
        hostname: "example.com",
        pathname: "/page1",
        time_bucket: time_bucket,
        dimension_type: "global",
        pageviews: 100,
        sessions: 50,
        total_duration: 500.0,
        duration_count: 10
      )
    end

    service = SiteStatsService.new(site)
    result = service.compute

    assert_equal :hourly, result[:granularity]
    assert_equal 1, result[:period_days]
    assert_equal 2400.0, result[:avg_daily_pageviews] # 100 * 24
    assert_equal 1200.0, result[:avg_daily_sessions] # 50 * 24
    assert_equal 50.0, result[:avg_daily_duration] # (500 * 24) / (10 * 24)
  end

  # Test daily stats computation
  test "computes daily stats correctly for mid-age sites" do
    site = Site.create!(name: "Medium Site", created_at: 7.days.ago)

    # Create daily stats for last 7 days
    start_date = 7.days.ago.to_date
    (0..6).each do |offset|
      date = start_date + offset.days
      DailyPageStat.create!(
        site_id: site.id,
        hostname: "example.com",
        pathname: "/page1",
        date: date,
        dimension_type: "global",
        pageviews: 100,
        sessions: 50,
        total_duration: 500.0,
        duration_count: 10
      )
    end

    service = SiteStatsService.new(site)
    result = service.compute

    assert_equal :daily, result[:granularity]
    assert_equal 7, result[:period_days]
    assert_equal 100.0, result[:avg_daily_pageviews]
    assert_equal 50.0, result[:avg_daily_sessions]
    assert_equal 50.0, result[:avg_daily_duration]
  end

  # Test weekly stats computation
  test "computes weekly stats correctly for old sites" do
    site = Site.create!(name: "Old Site", created_at: 30.days.ago)

    # Create weekly stats for last 4 weeks
    now = Time.current.to_date
    (0..3).each do |week_offset|
      week_start = (now - (3 - week_offset).weeks).beginning_of_week
      WeeklyPageStat.create!(
        site_id: site.id,
        hostname: "example.com",
        pathname: "/page1",
        week_start: week_start,
        dimension_type: "global",
        pageviews: 700,
        sessions: 350,
        total_duration: 3500.0,
        duration_count: 70
      )
    end

    service = SiteStatsService.new(site)
    result = service.compute

    assert_equal :weekly, result[:granularity]
    assert_equal 28, result[:period_days]
    assert_equal 100.0, result[:avg_daily_pageviews] # (700 * 4) / 28
    assert_equal 50.0, result[:avg_daily_sessions] # (350 * 4) / 28
    assert_equal 50.0, result[:avg_daily_duration] # (3500 * 4) / (70 * 4)
  end

  # Test handling sites with no stats
  test "returns empty data structure when site has no stats" do
    site = Site.create!(name: "No Data Site")

    service = SiteStatsService.new(site)
    result = service.compute

    assert_equal 0.0, result[:avg_daily_pageviews]
    assert_equal 0.0, result[:avg_daily_sessions]
    assert_nil result[:avg_daily_duration]
    assert_nil result[:top_page_by_sessions]
    assert_nil result[:top_page_by_duration]
  end

  # Test top page identification
  test "identifies top page by sessions for daily stats" do
    site = Site.create!(name: "Medium Site", created_at: 7.days.ago)

    start_date = 7.days.ago.to_date
    (0..6).each do |offset|
      date = start_date + offset.days

      DailyPageStat.create!(
        site_id: site.id,
        hostname: "example.com",
        pathname: "/page1",
        date: date,
        dimension_type: "global",
        pageviews: 100,
        sessions: 100,
        total_duration: 0.0,
        duration_count: 0
      )

      DailyPageStat.create!(
        site_id: site.id,
        hostname: "example.com",
        pathname: "/page2",
        date: date,
        dimension_type: "global",
        pageviews: 50,
        sessions: 50,
        total_duration: 0.0,
        duration_count: 0
      )
    end

    service = SiteStatsService.new(site)
    result = service.compute

    assert_equal "/page1", result[:top_page_by_sessions][:pathname]
    assert_equal 700, result[:top_page_by_sessions][:sessions]
  end

  test "identifies top page by average duration for daily stats" do
    site = Site.create!(name: "Medium Site", created_at: 7.days.ago)

    start_date = 7.days.ago.to_date
    (0..6).each do |offset|
      date = start_date + offset.days

      DailyPageStat.create!(
        site_id: site.id,
        hostname: "example.com",
        pathname: "/page1",
        date: date,
        dimension_type: "global",
        pageviews: 100,
        sessions: 50,
        total_duration: 100.0,
        duration_count: 10
      )

      DailyPageStat.create!(
        site_id: site.id,
        hostname: "example.com",
        pathname: "/page2",
        date: date,
        dimension_type: "global",
        pageviews: 50,
        sessions: 25,
        total_duration: 400.0,
        duration_count: 20
      )
    end

    service = SiteStatsService.new(site)
    result = service.compute

    assert_equal "/page2", result[:top_page_by_duration][:pathname]
    assert result[:top_page_by_duration][:avg_duration] > 19 && result[:top_page_by_duration][:avg_duration] < 21
  end

  # Test handling sites with partial data
  test "handles sites with no duration data" do
    site = Site.create!(name: "Medium Site", created_at: 7.days.ago)

    start_date = 7.days.ago.to_date
    (0..6).each do |offset|
      date = start_date + offset.days
      DailyPageStat.create!(
        site_id: site.id,
        hostname: "example.com",
        pathname: "/page1",
        date: date,
        dimension_type: "global",
        pageviews: 100,
        sessions: 50,
        total_duration: 0.0,
        duration_count: 0
      )
    end

    service = SiteStatsService.new(site)
    result = service.compute

    assert_nil result[:avg_daily_duration]
  end

  test "handles pages with no duration data in top pages" do
    site = Site.create!(name: "Medium Site", created_at: 7.days.ago)

    start_date = 7.days.ago.to_date
    (0..6).each do |offset|
      date = start_date + offset.days

      DailyPageStat.create!(
        site_id: site.id,
        hostname: "example.com",
        pathname: "/page1",
        date: date,
        dimension_type: "global",
        pageviews: 100,
        sessions: 50,
        total_duration: 0.0,
        duration_count: 0
      )
    end

    service = SiteStatsService.new(site)
    result = service.compute

    assert_nil result[:top_page_by_duration]
  end

  # Test that service returns all expected fields
  test "returns all expected fields in result" do
    site = Site.create!(name: "Test Site")

    service = SiteStatsService.new(site)
    result = service.compute

    assert result.key?(:site)
    assert result.key?(:granularity)
    assert result.key?(:period_days)
    assert result.key?(:avg_daily_pageviews)
    assert result.key?(:avg_daily_sessions)
    assert result.key?(:avg_daily_duration)
    assert result.key?(:top_page_by_sessions)
    assert result.key?(:top_page_by_duration)
  end

  test "granularity is included in empty data result" do
    site = Site.create!(name: "Test Site")

    service = SiteStatsService.new(site)
    result = service.compute

    assert result.key?(:granularity)
    assert_not_nil result[:granularity]
  end
end
