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

  test "ordered_by_week orders descending" do
    create_weekly_stat(sites(:my_blog), hostname: "a.com", week_start: @week_start)
    create_weekly_stat(sites(:my_blog), hostname: "b.com", week_start: @week_start + 1.week)
    create_weekly_stat(sites(:my_blog), hostname: "c.com", week_start: @week_start - 1.week)

    stats = WeeklyPageStat.ordered_by_week

    assert_equal ["b.com", "a.com", "c.com"], stats.pluck(:hostname)
  end
end
