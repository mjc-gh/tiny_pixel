# frozen_string_literal: true

require "test_helper"

class AggregationServiceTest < ActiveSupport::TestCase
  setup do
    @site = sites(:my_blog)
    @time_bucket = Time.zone.parse("2026-03-28 14:00:00")
    @service = AggregationService.new(@site)
  end

  test "aggregate_hourly returns empty result when no page views exist" do
    result = @service.aggregate_hourly(@time_bucket)

    assert_equal 0, result[:created]
    assert_equal 0, result[:updated]
    assert_equal 0, HourlyPageStat.count
  end

  test "aggregate_hourly creates stats from page views" do
    create_test_page_views(@time_bucket)

    result = @service.aggregate_hourly(@time_bucket)

    assert_equal 1, result[:created]
    assert_equal 0, result[:updated]

    stat = HourlyPageStat.find_by(site: @site, hostname: "example.com", pathname: "/page1")
    assert_not_nil stat
    assert_equal @time_bucket, stat.time_bucket
    assert_equal 3, stat.pageviews
    assert_equal 1, stat.visits
    assert_equal 1, stat.sessions
    assert_equal 2, stat.unique_pageviews
    assert_equal 1, stat.bounced_count
    assert_equal 60.0, stat.total_duration
    assert_equal 2, stat.duration_count
  end

  test "aggregate_hourly updates existing stats on re-run" do
    create_test_page_views(@time_bucket)

    @service.aggregate_hourly(@time_bucket)
    result = @service.aggregate_hourly(@time_bucket)

    assert_equal 0, result[:created]
    assert_equal 1, result[:updated]
    assert_equal 1, HourlyPageStat.count
  end

  test "aggregate_hourly rounds time to hour boundary" do
    time_mid_hour = @time_bucket + 30.minutes
    create_test_page_views(@time_bucket)

    @service.aggregate_hourly(time_mid_hour)

    stat = HourlyPageStat.first
    assert_equal @time_bucket, stat.time_bucket
  end

  test "aggregate_hourly creates aggregation log" do
    create_test_page_views(@time_bucket)

    @service.aggregate_hourly(@time_bucket)

    log = AggregationLog.find_by(site: @site, aggregation_type: "hourly")
    assert_not_nil log
    assert_equal @time_bucket, log.time_bucket
    assert_equal 1, log.rows_created
    assert_equal 0, log.rows_updated
    assert log.completed?
  end

  test "aggregate_daily returns empty result when no page views exist" do
    result = @service.aggregate_daily(@time_bucket.to_date)

    assert_equal 0, result[:created]
    assert_equal 0, result[:updated]
    assert_equal 0, DailyPageStat.count
  end

  test "aggregate_daily aggregates page views from raw data" do
    create_test_page_views_for_day(@time_bucket.to_date)

    result = @service.aggregate_daily(@time_bucket.to_date)

    assert_equal 1, result[:created]
    assert_equal 0, result[:updated]

    stat = DailyPageStat.find_by(site: @site, hostname: "example.com", pathname: "/page1")
    assert_not_nil stat
    assert_equal @time_bucket.to_date, stat.date
    assert_equal 6, stat.pageviews
    assert_equal 1, stat.visits
    assert_equal 1, stat.sessions
    assert_equal 3, stat.unique_pageviews
    assert_equal 2, stat.bounced_count
    assert_equal 120.0, stat.total_duration
    assert_equal 4, stat.duration_count
  end

  test "aggregate_daily updates existing stats on re-run" do
    create_test_page_views_for_day(@time_bucket.to_date)

    @service.aggregate_daily(@time_bucket.to_date)
    result = @service.aggregate_daily(@time_bucket.to_date)

    assert_equal 0, result[:created]
    assert_equal 1, result[:updated]
    assert_equal 1, DailyPageStat.count
  end

  test "aggregate_weekly returns empty result when no page views exist" do
    week_start = @time_bucket.to_date.beginning_of_week(:monday)
    result = @service.aggregate_weekly(week_start)

    assert_equal 0, result[:created]
    assert_equal 0, result[:updated]
    assert_equal 0, WeeklyPageStat.count
  end

  test "aggregate_weekly aggregates page views from raw data" do
    week_start = @time_bucket.to_date.beginning_of_week(:monday)
    create_test_page_views_for_week(week_start)

    result = @service.aggregate_weekly(week_start)

    assert_equal 1, result[:created]
    assert_equal 0, result[:updated]

    stat = WeeklyPageStat.find_by(site: @site, hostname: "example.com", pathname: "/page1")
    assert_not_nil stat
    assert_equal week_start, stat.week_start
    assert_equal 14, stat.pageviews
    assert_equal 1, stat.visits
    assert_equal 1, stat.sessions
    assert_equal 5, stat.unique_pageviews
    assert_equal 6, stat.bounced_count
    assert_equal 290.0, stat.total_duration
    assert_equal 12, stat.duration_count
  end

  test "aggregate_weekly updates existing stats on re-run" do
    week_start = @time_bucket.to_date.beginning_of_week(:monday)
    create_test_page_views_for_week(week_start)

    @service.aggregate_weekly(week_start)
    result = @service.aggregate_weekly(week_start)

    assert_equal 0, result[:created]
    assert_equal 1, result[:updated]
    assert_equal 1, WeeklyPageStat.count
  end

  test "aggregate_weekly normalizes to Monday start" do
    week_start = @time_bucket.to_date.beginning_of_week(:monday)
    mid_week = week_start + 3.days
    create_test_page_views_for_week(week_start)

    @service.aggregate_weekly(mid_week)

    stat = WeeklyPageStat.first
    assert_equal week_start, stat.week_start
  end

  test "aggregate_recent processes all granularities" do
    recent_time = Time.current.beginning_of_hour - 1.hour
    create_test_page_views(recent_time)

    @service.aggregate_recent(lookback_hours: 48)

    assert HourlyPageStat.exists?
    assert DailyPageStat.exists?
    assert WeeklyPageStat.exists?
  end

  test "class method aggregate_all_sites processes all sites" do
    recent_time = Time.current.beginning_of_hour - 1.hour
    create_test_page_views(recent_time)

    AggregationService.aggregate_all_sites(lookback_hours: 48)

    assert HourlyPageStat.exists?(site: @site)
  end

  test "aggregate_hourly with global dimension creates global stats" do
    create_test_page_views(@time_bucket)

    result = @service.aggregate_hourly(@time_bucket, dimension: "global")

    assert_equal 1, result[:created]
    stat = HourlyPageStat.find_by(site: @site, hostname: "example.com", pathname: "/page1")
    assert_not_nil stat
    assert_equal "global", stat.dimension
  end

  test "aggregate_daily with global dimension creates global stats" do
    create_test_page_views_for_day(@time_bucket.to_date)

    result = @service.aggregate_daily(@time_bucket.to_date, dimension: "global")

    assert_equal 1, result[:created]
    stat = DailyPageStat.find_by(site: @site, hostname: "example.com", pathname: "/page1")
    assert_not_nil stat
    assert_equal "global", stat.dimension
  end

  test "aggregate_weekly with global dimension creates global stats" do
    week_start = @time_bucket.to_date.beginning_of_week(:monday)
    create_test_page_views_for_week(week_start)

    result = @service.aggregate_weekly(week_start, dimension: "global")

    assert_equal 1, result[:created]
    stat = WeeklyPageStat.find_by(site: @site, hostname: "example.com", pathname: "/page1")
    assert_not_nil stat
    assert_equal "global", stat.dimension
  end

  test "aggregate_hourly with country dimension creates country dimension stats" do
    create_test_page_views(@time_bucket)

    result = @service.aggregate_hourly(@time_bucket, dimension: "country:US")

    assert_equal 1, result[:created]
    stat = HourlyPageStat.find_by(site: @site, hostname: "example.com", pathname: "/page1")
    assert_not_nil stat
    assert_equal "country:US", stat.dimension
  end

  test "aggregate_daily with country dimension creates country dimension stats" do
    create_test_page_views_for_day(@time_bucket.to_date)

    result = @service.aggregate_daily(@time_bucket.to_date, dimension: "country:US")

    assert_equal 1, result[:created]
    stat = DailyPageStat.find_by(site: @site, hostname: "example.com", pathname: "/page1")
    assert_not_nil stat
    assert_equal "country:US", stat.dimension
  end

  test "aggregate_weekly with country dimension creates country dimension stats" do
    week_start = @time_bucket.to_date.beginning_of_week(:monday)
    create_test_page_views_for_week(week_start)

    result = @service.aggregate_weekly(week_start, dimension: "country:US")

    assert_equal 1, result[:created]
    stat = WeeklyPageStat.find_by(site: @site, hostname: "example.com", pathname: "/page1")
    assert_not_nil stat
    assert_equal "country:US", stat.dimension
  end

  test "aggregation still works with backward compatibility (no dimension parameter)" do
    create_test_page_views(@time_bucket)

    result = @service.aggregate_hourly(@time_bucket)

    assert_equal 1, result[:created]
    stat = HourlyPageStat.find_by(site: @site, hostname: "example.com", pathname: "/page1")
    assert_not_nil stat
    assert_equal "global", stat.dimension
  end

  test "dimension_expression_for_type returns correct SQL for country" do
    expr = AggregationService.dimension_expression_for_type("country")

    assert_equal "visitors.country", expr
  end

  test "dimension_expression_for_type returns correct SQL for browser" do
    expr = AggregationService.dimension_expression_for_type("browser")

    assert_equal "visitors.browser", expr
  end

  test "dimension_expression_for_type returns correct SQL for device_type" do
    expr = AggregationService.dimension_expression_for_type("device_type")

    assert_equal "visitors.device_type", expr
  end

  test "dimension_expression_for_type returns nil for unknown dimension" do
    expr = AggregationService.dimension_expression_for_type("unknown")

    assert_nil expr
  end

  test "dimension_expression_for_type returns correct handling for referrer_hostname" do
    expr = AggregationService.dimension_expression_for_type("referrer_hostname")

    assert_equal "referrer_hostname", expr
  end

  test "format_dimension_value returns 'global' when dimension is 'global'" do
    formatted = AggregationService.format_dimension_value("global", "any_value")

    assert_equal "global", formatted
  end

  test "format_dimension_value formats dimension correctly for country" do
    formatted = AggregationService.format_dimension_value("country:US", "US")

    assert_equal "country:US", formatted
  end

  test "format_dimension_value formats dimension correctly for browser" do
    formatted = AggregationService.format_dimension_value("browser:chrome", "1")

    assert_equal "browser:1", formatted
  end

  test "format_dimension_value formats dimension correctly for device_type" do
    formatted = AggregationService.format_dimension_value("device_type:mobile", "2")

    assert_equal "device_type:2", formatted
  end

  test "aggregate_hourly with referrer_hostname dimension creates referrer dimension stats" do
    create_test_page_views_with_referrer(@time_bucket, "google.com")

    result = @service.aggregate_hourly(@time_bucket, dimension: "referrer_hostname:google.com")

    assert_equal 1, result[:created]
    stat = HourlyPageStat.find_by(site: @site, hostname: "example.com", pathname: "/page1")
    assert_not_nil stat
    assert_equal "referrer_hostname:google.com", stat.dimension
  end

  test "aggregate_hourly with referrer_hostname correctly aggregates all page views in a visit" do
    create_test_page_views_with_referrer(@time_bucket, "google.com")

    result = @service.aggregate_hourly(@time_bucket, dimension: "referrer_hostname:google.com")

    assert_equal 1, result[:created]
    stat = HourlyPageStat.find_by(site: @site, hostname: "example.com", pathname: "/page1")
    # Should have 3 page views even though only first one has referrer_hostname set
    assert_equal 3, stat.pageviews
    assert_equal 1, stat.visits
  end

  test "aggregate_hourly with referrer_hostname handles direct traffic (NULL referrer)" do
    create_test_page_views_with_direct_traffic(@time_bucket)

    result = @service.aggregate_hourly(@time_bucket, dimension: "referrer_hostname:direct")

    assert_equal 1, result[:created]
    stat = HourlyPageStat.find_by(site: @site, hostname: "example.com", pathname: "/page1")
    assert_not_nil stat
    assert_equal "referrer_hostname:direct", stat.dimension
    assert_equal 3, stat.pageviews
  end

  test "aggregate_daily with referrer_hostname dimension creates referrer dimension stats" do
    create_test_page_views_with_referrer_for_day(@time_bucket.to_date, "github.com")

    result = @service.aggregate_daily(@time_bucket.to_date, dimension: "referrer_hostname:github.com")

    assert_equal 1, result[:created]
    stat = DailyPageStat.find_by(site: @site, hostname: "example.com", pathname: "/page1")
    assert_not_nil stat
    assert_equal "referrer_hostname:github.com", stat.dimension
  end

  test "aggregate_daily with referrer_hostname correctly aggregates all page views in a visit" do
    create_test_page_views_with_referrer_for_day(@time_bucket.to_date, "github.com")

    result = @service.aggregate_daily(@time_bucket.to_date, dimension: "referrer_hostname:github.com")

    assert_equal 1, result[:created]
    stat = DailyPageStat.find_by(site: @site, hostname: "example.com", pathname: "/page1")
    # Should have 6 page views even though only first one has referrer_hostname set
    assert_equal 6, stat.pageviews
    assert_equal 1, stat.visits
  end

  test "aggregate_weekly with referrer_hostname dimension creates referrer dimension stats" do
    week_start = @time_bucket.to_date.beginning_of_week(:monday)
    create_test_page_views_with_referrer_for_week(week_start, "twitter.com")

    result = @service.aggregate_weekly(week_start, dimension: "referrer_hostname:twitter.com")

    assert_equal 1, result[:created]
    stat = WeeklyPageStat.find_by(site: @site, hostname: "example.com", pathname: "/page1")
    assert_not_nil stat
    assert_equal "referrer_hostname:twitter.com", stat.dimension
  end

  private

  def create_test_page_views(time_bucket)
    visitor = Visitor.create!(
      digest: "visitor_digest_1",
      property_id: @site.id,
      browser: :chrome,
      device_type: :desktop,
      country: "US",
      salt_version: @site.salt_version
    )

    PageView.create!(
      digest: "pv_digest_1",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      created_at: time_bucket + 5.minutes,
      new_visit: true,
      new_session: true,
      is_unique: true,
      bounced: false,
      duration: 30
    )

    PageView.create!(
      digest: "pv_digest_2",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      created_at: time_bucket + 15.minutes,
      new_visit: false,
      new_session: false,
      is_unique: true,
      bounced: false,
      duration: 30
    )

    PageView.create!(
      digest: "pv_digest_3",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      created_at: time_bucket + 25.minutes,
      new_visit: false,
      new_session: false,
      is_unique: false,
      bounced: true,
      duration: nil
    )
  end

  def create_test_page_views_for_day(date)
    visitor = Visitor.find_or_create_by!(digest: "visitor_digest_daily") do |v|
      v.property_id = @site.id
      v.browser = :chrome
      v.device_type = :desktop
      v.country = "US"
      v.salt_version = @site.salt_version
    end

    base_time = date.to_datetime

    PageView.create!(
      digest: "pv_daily_1",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      created_at: base_time + 2.hours,
      new_visit: true,
      new_session: true,
      is_unique: true,
      bounced: false,
      duration: 30
    )

    PageView.create!(
      digest: "pv_daily_2",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      created_at: base_time + 3.hours,
      new_visit: false,
      new_session: false,
      is_unique: true,
      bounced: false,
      duration: 30
    )

    PageView.create!(
      digest: "pv_daily_3",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      created_at: base_time + 4.hours,
      new_visit: false,
      new_session: false,
      is_unique: false,
      bounced: true,
      duration: nil
    )

    PageView.create!(
      digest: "pv_daily_4",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      created_at: base_time + 10.hours,
      new_visit: false,
      new_session: true,
      is_unique: true,
      bounced: false,
      duration: 30
    )

    PageView.create!(
      digest: "pv_daily_5",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      created_at: base_time + 11.hours,
      new_visit: false,
      new_session: false,
      is_unique: false,
      bounced: false,
      duration: 30
    )

    PageView.create!(
      digest: "pv_daily_6",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      created_at: base_time + 12.hours,
      new_visit: false,
      new_session: false,
      is_unique: false,
      bounced: true,
      duration: nil
    )
  end

  def create_test_page_views_for_week(week_start)
    visitor = Visitor.find_or_create_by!(digest: "visitor_digest_weekly") do |v|
      v.property_id = @site.id
      v.browser = :chrome
      v.device_type = :desktop
      v.country = "US"
      v.salt_version = @site.salt_version
    end

    base_time = week_start.to_datetime

    PageView.create!(
      digest: "pv_weekly_1",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      created_at: base_time + 1.day + 2.hours,
      new_visit: true,
      new_session: true,
      is_unique: true,
      bounced: false,
      duration: 30
    )

    PageView.create!(
      digest: "pv_weekly_2",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      created_at: base_time + 1.day + 3.hours,
      new_visit: false,
      new_session: false,
      is_unique: true,
      bounced: false,
      duration: 30
    )

    PageView.create!(
      digest: "pv_weekly_3",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      created_at: base_time + 2.days + 4.hours,
      new_visit: false,
      new_session: true,
      is_unique: true,
      bounced: false,
      duration: 30
    )

    PageView.create!(
      digest: "pv_weekly_4",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      created_at: base_time + 2.days + 5.hours,
      new_visit: false,
      new_session: false,
      is_unique: false,
      bounced: true,
      duration: nil
    )

    PageView.create!(
      digest: "pv_weekly_5",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      created_at: base_time + 3.days + 6.hours,
      new_visit: false,
      new_session: false,
      is_unique: true,
      bounced: false,
      duration: 30
    )

    PageView.create!(
      digest: "pv_weekly_6",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      created_at: base_time + 3.days + 7.hours,
      new_visit: false,
      new_session: false,
      is_unique: false,
      bounced: true,
      duration: nil
    )

    PageView.create!(
      digest: "pv_weekly_7",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      created_at: base_time + 4.days + 8.hours,
      new_visit: false,
      new_session: true,
      is_unique: true,
      bounced: false,
      duration: 30
    )

    7.times do |i|
      PageView.create!(
        digest: "pv_weekly_extra_#{i}",
        visitor_digest: visitor.digest,
        hostname: "example.com",
        pathname: "/page1",
        created_at: base_time + 5.days + i.hours,
        new_visit: false,
        new_session: false,
        is_unique: false,
        bounced: i.even?,
        duration: 20
      )
    end
  end

  def create_test_page_views_with_referrer(time_bucket, referrer_hostname)
    visitor = Visitor.create!(
      digest: "visitor_digest_referrer_1",
      property_id: @site.id,
      browser: :chrome,
      device_type: :desktop,
      country: "US",
      salt_version: @site.salt_version
    )

    # First page view with referrer_hostname set (new_visit=true)
    PageView.create!(
      digest: "pv_referrer_1",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      referrer_hostname: referrer_hostname,
      created_at: time_bucket + 5.minutes,
      new_visit: true,
      new_session: true,
      is_unique: true,
      bounced: false,
      duration: 30
    )

    # Second page view without referrer_hostname (new_visit=false)
    PageView.create!(
      digest: "pv_referrer_2",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      referrer_hostname: nil,
      created_at: time_bucket + 15.minutes,
      new_visit: false,
      new_session: false,
      is_unique: true,
      bounced: false,
      duration: 30
    )

    # Third page view without referrer_hostname (new_visit=false)
    PageView.create!(
      digest: "pv_referrer_3",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      referrer_hostname: nil,
      created_at: time_bucket + 25.minutes,
      new_visit: false,
      new_session: false,
      is_unique: false,
      bounced: true,
      duration: nil
    )
  end

  def create_test_page_views_with_direct_traffic(time_bucket)
    visitor = Visitor.create!(
      digest: "visitor_digest_direct_1",
      property_id: @site.id,
      browser: :chrome,
      device_type: :desktop,
      country: "US",
      salt_version: @site.salt_version
    )

    # First page view with no referrer_hostname (direct traffic)
    PageView.create!(
      digest: "pv_direct_1",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      referrer_hostname: nil,
      created_at: time_bucket + 5.minutes,
      new_visit: true,
      new_session: true,
      is_unique: true,
      bounced: false,
      duration: 30
    )

    # Second page view without referrer_hostname
    PageView.create!(
      digest: "pv_direct_2",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      referrer_hostname: nil,
      created_at: time_bucket + 15.minutes,
      new_visit: false,
      new_session: false,
      is_unique: true,
      bounced: false,
      duration: 30
    )

    # Third page view without referrer_hostname
    PageView.create!(
      digest: "pv_direct_3",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      referrer_hostname: nil,
      created_at: time_bucket + 25.minutes,
      new_visit: false,
      new_session: false,
      is_unique: false,
      bounced: true,
      duration: nil
    )
  end

  def create_test_page_views_with_referrer_for_day(date, referrer_hostname)
    visitor = Visitor.find_or_create_by!(digest: "visitor_digest_referrer_daily") do |v|
      v.property_id = @site.id
      v.browser = :chrome
      v.device_type = :desktop
      v.country = "US"
      v.salt_version = @site.salt_version
    end

    base_time = date.to_datetime

    PageView.create!(
      digest: "pv_referrer_daily_1",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      referrer_hostname: referrer_hostname,
      created_at: base_time + 2.hours,
      new_visit: true,
      new_session: true,
      is_unique: true,
      bounced: false,
      duration: 30
    )

    PageView.create!(
      digest: "pv_referrer_daily_2",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      referrer_hostname: nil,
      created_at: base_time + 3.hours,
      new_visit: false,
      new_session: false,
      is_unique: true,
      bounced: false,
      duration: 30
    )

    PageView.create!(
      digest: "pv_referrer_daily_3",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      referrer_hostname: nil,
      created_at: base_time + 4.hours,
      new_visit: false,
      new_session: false,
      is_unique: false,
      bounced: true,
      duration: nil
    )

    PageView.create!(
      digest: "pv_referrer_daily_4",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      referrer_hostname: nil,
      created_at: base_time + 10.hours,
      new_visit: false,
      new_session: true,
      is_unique: true,
      bounced: false,
      duration: 30
    )

    PageView.create!(
      digest: "pv_referrer_daily_5",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      referrer_hostname: nil,
      created_at: base_time + 11.hours,
      new_visit: false,
      new_session: false,
      is_unique: false,
      bounced: false,
      duration: 30
    )

    PageView.create!(
      digest: "pv_referrer_daily_6",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      referrer_hostname: nil,
      created_at: base_time + 12.hours,
      new_visit: false,
      new_session: false,
      is_unique: false,
      bounced: true,
      duration: nil
    )
  end

  def create_test_page_views_with_referrer_for_week(week_start, referrer_hostname)
    visitor = Visitor.find_or_create_by!(digest: "visitor_digest_referrer_weekly") do |v|
      v.property_id = @site.id
      v.browser = :chrome
      v.device_type = :desktop
      v.country = "US"
      v.salt_version = @site.salt_version
    end

    base_time = week_start.to_datetime

    PageView.create!(
      digest: "pv_referrer_weekly_1",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      referrer_hostname: referrer_hostname,
      created_at: base_time + 1.day + 2.hours,
      new_visit: true,
      new_session: true,
      is_unique: true,
      bounced: false,
      duration: 30
    )

    PageView.create!(
      digest: "pv_referrer_weekly_2",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      referrer_hostname: nil,
      created_at: base_time + 1.day + 3.hours,
      new_visit: false,
      new_session: false,
      is_unique: true,
      bounced: false,
      duration: 30
    )

    PageView.create!(
      digest: "pv_referrer_weekly_3",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      referrer_hostname: nil,
      created_at: base_time + 2.days + 4.hours,
      new_visit: false,
      new_session: true,
      is_unique: true,
      bounced: false,
      duration: 30
    )

    PageView.create!(
      digest: "pv_referrer_weekly_4",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      referrer_hostname: nil,
      created_at: base_time + 2.days + 5.hours,
      new_visit: false,
      new_session: false,
      is_unique: false,
      bounced: true,
      duration: nil
    )

    PageView.create!(
      digest: "pv_referrer_weekly_5",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      referrer_hostname: nil,
      created_at: base_time + 3.days + 6.hours,
      new_visit: false,
      new_session: false,
      is_unique: true,
      bounced: false,
      duration: 30
    )

    PageView.create!(
      digest: "pv_referrer_weekly_6",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      referrer_hostname: nil,
      created_at: base_time + 3.days + 7.hours,
      new_visit: false,
      new_session: false,
      is_unique: false,
      bounced: true,
      duration: nil
    )

    PageView.create!(
      digest: "pv_referrer_weekly_7",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/page1",
      referrer_hostname: nil,
      created_at: base_time + 4.days + 8.hours,
      new_visit: false,
      new_session: true,
      is_unique: true,
      bounced: false,
      duration: 30
    )

    7.times do |i|
      PageView.create!(
        digest: "pv_referrer_weekly_extra_#{i}",
        visitor_digest: visitor.digest,
        hostname: "example.com",
        pathname: "/page1",
        referrer_hostname: nil,
        created_at: base_time + 5.days + i.hours,
        new_visit: false,
        new_session: false,
        is_unique: false,
        bounced: i.even?,
        duration: 20
      )
    end
  end
end
