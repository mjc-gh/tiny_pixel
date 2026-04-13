# frozen_string_literal: true

require "test_helper"

class DailyPageStatTest < ActiveSupport::TestCase
  setup do
    @site = sites(:my_blog)
    @date = Date.new(2026, 3, 28)
  end

  test "avg_duration returns nil when duration_count is zero" do
    stat = DailyPageStat.new(total_duration: 0, duration_count: 0)

    assert_nil stat.avg_duration
  end

  test "avg_duration calculates average correctly" do
    stat = DailyPageStat.new(total_duration: 300, duration_count: 10)

    assert_equal 30.0, stat.avg_duration
  end

  test "bounce_rate returns nil when pageviews is zero" do
    stat = DailyPageStat.new(bounced_count: 0, pageviews: 0)

    assert_nil stat.bounce_rate
  end

  test "bounce_rate calculates percentage correctly" do
    stat = DailyPageStat.new(bounced_count: 25, pageviews: 100)

    assert_equal 25.0, stat.bounce_rate
  end

  test "for_site scope filters by site_id" do
    create_daily_stat(@site, pathname: "/test", date: @date)

    assert_equal 1, DailyPageStat.for_site(@site.id).count
    assert_equal 0, DailyPageStat.for_site(999).count
  end

  test "for_date_range scope filters by date" do
    create_daily_stat(@site, pathname: "/test", date: @date)

    assert_equal 1, DailyPageStat.for_date_range(@date - 1.day, @date + 1.day).count
    assert_equal 0, DailyPageStat.for_date_range(@date + 2.days, @date + 3.days).count
  end

  test "for_hostname scope filters by hostname" do
    create_daily_stat(@site, pathname: "/test", date: @date)

    assert_equal 1, DailyPageStat.for_hostname("example.com").count
    assert_equal 0, DailyPageStat.for_hostname("other.com").count
  end

  test "for_pathname scope filters by pathname" do
    create_daily_stat(@site, pathname: "/test", date: @date)

    assert_equal 1, DailyPageStat.for_pathname("/test").count
    assert_equal 0, DailyPageStat.for_pathname("/other").count
  end

  test "ordered_by_pageviews orders descending" do
    create_daily_stat(@site, hostname: "a.com", date: @date, pageviews: 10)
    create_daily_stat(@site, hostname: "b.com", date: @date, pageviews: 50)
    create_daily_stat(@site, hostname: "c.com", date: @date, pageviews: 25)

    stats = DailyPageStat.ordered_by_pageviews

    assert_equal [50, 25, 10], stats.pluck(:pageviews)
  end

  test "ordered_by_date orders descending" do
    create_daily_stat(@site, hostname: "a.com", date: @date)
    create_daily_stat(@site, hostname: "b.com", date: @date + 1.day)
    create_daily_stat(@site, hostname: "c.com", date: @date - 1.day)

    stats = DailyPageStat.ordered_by_date

    assert_equal ["b.com", "a.com", "c.com"], stats.pluck(:hostname)
  end

  test "global scope filters by dimension_type = 'global'" do
    create_daily_stat(@site, pathname: "/test", date: @date, dimension_type: "global")
    create_daily_stat(@site, pathname: "/test2", date: @date, dimension_type: "country", dimension_value: "US")

    assert_equal 1, DailyPageStat.global.count
    assert_equal "global", DailyPageStat.global.first.dimension_type
  end

  test "for_dimension scope filters by specific dimension type and value" do
    create_daily_stat(@site, pathname: "/test", date: @date, dimension_type: "country", dimension_value: "US")
    create_daily_stat(@site, pathname: "/test2", date: @date, dimension_type: "country", dimension_value: "GB")

    assert_equal 1, DailyPageStat.for_dimension("country", "US").count
    result = DailyPageStat.for_dimension("country", "US").first
    assert_equal "country", result.dimension_type
    assert_equal "US", result.dimension_value
  end

  test "for_dimension_type scope filters by dimension type" do
    create_daily_stat(@site, pathname: "/test", date: @date, dimension_type: "country", dimension_value: "US")
    create_daily_stat(@site, pathname: "/test2", date: @date, dimension_type: "country", dimension_value: "GB")
    create_daily_stat(@site, pathname: "/test3", date: @date, dimension_type: "browser", dimension_value: "chrome")

    assert_equal 2, DailyPageStat.for_dimension_type("country").count
    assert_equal 1, DailyPageStat.for_dimension_type("browser").count
  end
end
