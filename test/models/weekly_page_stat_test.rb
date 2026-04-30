# frozen_string_literal: true

require "test_helper"
require "support/shared_stat_tests"

class WeeklyPageStatTest < ActiveSupport::TestCase
  include SharedStatTests

  setup do
    @week_start = Date.new(2026, 3, 23)
  end

  def stat_class
    WeeklyPageStat
  end

  def create_stat(site, **attrs)
    attrs[:week_start] ||= @week_start
    create_weekly_stat(site, **attrs)
  end

  test "for_date_range scope filters by week_start" do
    create_weekly_stat(sites(:my_blog), pathname: "/test", week_start: @week_start)

    assert_equal 1, WeeklyPageStat.for_date_range(@week_start - 1.week, @week_start + 1.week).count
    assert_equal 0, WeeklyPageStat.for_date_range(@week_start + 2.weeks, @week_start + 3.weeks).count
  end

  test "for_date_range scope filters by start_date only" do
    create_weekly_stat(sites(:my_blog), pathname: "/test", week_start: @week_start)
    create_weekly_stat(sites(:my_blog), pathname: "/about", week_start: @week_start + 1.week)
    create_weekly_stat(sites(:my_blog), pathname: "/contact", week_start: @week_start - 1.week)

    stats = WeeklyPageStat.for_date_range(@week_start, nil)

    assert_equal 2, stats.count
    assert_equal ["/about", "/test"], stats.pluck(:pathname).sort
  end

  test "for_date_range scope filters by end_date only" do
    create_weekly_stat(sites(:my_blog), pathname: "/test", week_start: @week_start)
    create_weekly_stat(sites(:my_blog), pathname: "/about", week_start: @week_start + 1.week)
    create_weekly_stat(sites(:my_blog), pathname: "/contact", week_start: @week_start - 1.week)

    stats = WeeklyPageStat.for_date_range(nil, @week_start)

    assert_equal 2, stats.count
    assert_equal ["/contact", "/test"], stats.pluck(:pathname).sort
  end

  test "ordered_by_week orders descending" do
    create_weekly_stat(sites(:my_blog), hostname: "a.com", week_start: @week_start)
    create_weekly_stat(sites(:my_blog), hostname: "b.com", week_start: @week_start + 1.week)
    create_weekly_stat(sites(:my_blog), hostname: "c.com", week_start: @week_start - 1.week)

    stats = WeeklyPageStat.ordered_by_week

    assert_equal ["b.com", "a.com", "c.com"], stats.pluck(:hostname)
  end

  test "older_than scope filters by week_start" do
    create_weekly_stat(sites(:my_blog), hostname: "old.com", week_start: @week_start - 10.weeks)
    create_weekly_stat(sites(:my_blog), hostname: "recent.com", week_start: @week_start)

    cutoff = (@week_start - 5.weeks).to_datetime
    stats = WeeklyPageStat.older_than(cutoff)

    assert_equal 1, stats.count
    assert_equal "old.com", stats.first.hostname
  end

  test "older_than scope excludes stats at or after cutoff date" do
    create_weekly_stat(sites(:my_blog), hostname: "a.com", week_start: @week_start - 10.weeks)
    create_weekly_stat(sites(:my_blog), hostname: "b.com", week_start: @week_start - 5.weeks)
    create_weekly_stat(sites(:my_blog), hostname: "c.com", week_start: @week_start)

    cutoff = (@week_start - 5.weeks).to_datetime
    stats = WeeklyPageStat.older_than(cutoff)

    assert_equal 1, stats.count
    assert_equal ["a.com"], stats.pluck(:hostname)
  end
end
