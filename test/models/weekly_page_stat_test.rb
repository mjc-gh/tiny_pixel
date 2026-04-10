# frozen_string_literal: true

require "test_helper"

class WeeklyPageStatTest < ActiveSupport::TestCase
  setup do
    @site = sites(:my_blog)
    @week_start = Date.new(2026, 3, 23)
  end

  test "avg_duration returns nil when duration_count is zero" do
    stat = WeeklyPageStat.new(total_duration: 0, duration_count: 0)

    assert_nil stat.avg_duration
  end

  test "avg_duration calculates average correctly" do
    stat = WeeklyPageStat.new(total_duration: 300, duration_count: 10)

    assert_equal 30.0, stat.avg_duration
  end

  test "bounce_rate returns nil when pageviews is zero" do
    stat = WeeklyPageStat.new(bounced_count: 0, pageviews: 0)

    assert_nil stat.bounce_rate
  end

  test "bounce_rate calculates percentage correctly" do
    stat = WeeklyPageStat.new(bounced_count: 25, pageviews: 100)

    assert_equal 25.0, stat.bounce_rate
  end

  test "for_site scope filters by site_id" do
    WeeklyPageStat.create!(
      site: @site,
      hostname: "example.com",
      pathname: "/test",
      week_start: @week_start
    )

    assert_equal 1, WeeklyPageStat.for_site(@site.id).count
    assert_equal 0, WeeklyPageStat.for_site(999).count
  end

  test "for_date_range scope filters by week_start" do
    WeeklyPageStat.create!(
      site: @site,
      hostname: "example.com",
      pathname: "/test",
      week_start: @week_start
    )

    assert_equal 1, WeeklyPageStat.for_date_range(@week_start - 1.week, @week_start + 1.week).count
    assert_equal 0, WeeklyPageStat.for_date_range(@week_start + 2.weeks, @week_start + 3.weeks).count
  end

  test "for_hostname scope filters by hostname" do
    WeeklyPageStat.create!(
      site: @site,
      hostname: "example.com",
      pathname: "/test",
      week_start: @week_start
    )

    assert_equal 1, WeeklyPageStat.for_hostname("example.com").count
    assert_equal 0, WeeklyPageStat.for_hostname("other.com").count
  end

  test "for_pathname scope filters by pathname" do
    WeeklyPageStat.create!(
      site: @site,
      hostname: "example.com",
      pathname: "/test",
      week_start: @week_start
    )

    assert_equal 1, WeeklyPageStat.for_pathname("/test").count
    assert_equal 0, WeeklyPageStat.for_pathname("/other").count
  end

  test "ordered_by_pageviews orders descending" do
    WeeklyPageStat.create!(site: @site, hostname: "a.com", pathname: "/", week_start: @week_start, pageviews: 10)
    WeeklyPageStat.create!(site: @site, hostname: "b.com", pathname: "/", week_start: @week_start, pageviews: 50)
    WeeklyPageStat.create!(site: @site, hostname: "c.com", pathname: "/", week_start: @week_start, pageviews: 25)

    stats = WeeklyPageStat.ordered_by_pageviews

    assert_equal [50, 25, 10], stats.pluck(:pageviews)
  end

  test "ordered_by_week orders descending" do
    WeeklyPageStat.create!(site: @site, hostname: "a.com", pathname: "/", week_start: @week_start)
    WeeklyPageStat.create!(site: @site, hostname: "b.com", pathname: "/", week_start: @week_start + 1.week)
    WeeklyPageStat.create!(site: @site, hostname: "c.com", pathname: "/", week_start: @week_start - 1.week)

    stats = WeeklyPageStat.ordered_by_week

    assert_equal ["b.com", "a.com", "c.com"], stats.pluck(:hostname)
  end

  test "global scope filters by dimension_type = 'global'" do
    WeeklyPageStat.create!(
      site: @site,
      hostname: "example.com",
      pathname: "/test",
      week_start: @week_start,
      dimension_type: "global"
    )
    WeeklyPageStat.create!(
      site: @site,
      hostname: "example.com",
      pathname: "/test2",
      week_start: @week_start,
      dimension_type: "country",
      dimension_value: "US"
    )

    assert_equal 1, WeeklyPageStat.global.count
    assert_equal "global", WeeklyPageStat.global.first.dimension_type
  end

  test "for_dimension scope filters by specific dimension type and value" do
    WeeklyPageStat.create!(
      site: @site,
      hostname: "example.com",
      pathname: "/test",
      week_start: @week_start,
      dimension_type: "country",
      dimension_value: "US"
    )
    WeeklyPageStat.create!(
      site: @site,
      hostname: "example.com",
      pathname: "/test2",
      week_start: @week_start,
      dimension_type: "country",
      dimension_value: "GB"
    )

    assert_equal 1, WeeklyPageStat.for_dimension("country", "US").count
    result = WeeklyPageStat.for_dimension("country", "US").first
    assert_equal "country", result.dimension_type
    assert_equal "US", result.dimension_value
  end

  test "for_dimension_type scope filters by dimension type" do
    WeeklyPageStat.create!(
      site: @site,
      hostname: "example.com",
      pathname: "/test",
      week_start: @week_start,
      dimension_type: "country",
      dimension_value: "US"
    )
    WeeklyPageStat.create!(
      site: @site,
      hostname: "example.com",
      pathname: "/test2",
      week_start: @week_start,
      dimension_type: "country",
      dimension_value: "GB"
    )
    WeeklyPageStat.create!(
      site: @site,
      hostname: "example.com",
      pathname: "/test3",
      week_start: @week_start,
      dimension_type: "browser",
      dimension_value: "chrome"
    )

    assert_equal 2, WeeklyPageStat.for_dimension_type("country").count
    assert_equal 1, WeeklyPageStat.for_dimension_type("browser").count
  end
end
