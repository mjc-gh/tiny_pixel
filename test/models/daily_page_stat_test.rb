# frozen_string_literal: true

require "test_helper"
require "support/shared_stat_tests"

class DailyPageStatTest < ActiveSupport::TestCase
  include SharedStatTests

  setup do
    @date = Date.new(2026, 3, 28)
  end

  def stat_class
    DailyPageStat
  end

  def create_stat(site, **attrs)
    attrs[:date] ||= @date
    create_daily_stat(site, **attrs)
  end

  test "for_date_range scope filters by date" do
    create_daily_stat(sites(:my_blog), pathname: "/test", date: @date)

    assert_equal 1, DailyPageStat.for_date_range(@date - 1.day, @date + 1.day).count
    assert_equal 0, DailyPageStat.for_date_range(@date + 2.days, @date + 3.days).count
  end

  test "for_date_range scope filters by start_date only" do
    create_daily_stat(sites(:my_blog), pathname: "/test", date: @date)
    create_daily_stat(sites(:my_blog), pathname: "/about", date: @date + 1.day)
    create_daily_stat(sites(:my_blog), pathname: "/contact", date: @date - 1.day)

    stats = DailyPageStat.for_date_range(@date, nil)

    assert_equal 2, stats.count
    assert_equal ["/about", "/test"], stats.pluck(:pathname).sort
  end

  test "for_date_range scope filters by end_date only" do
    create_daily_stat(sites(:my_blog), pathname: "/test", date: @date)
    create_daily_stat(sites(:my_blog), pathname: "/about", date: @date + 1.day)
    create_daily_stat(sites(:my_blog), pathname: "/contact", date: @date - 1.day)

    stats = DailyPageStat.for_date_range(nil, @date)

    assert_equal 2, stats.count
    assert_equal ["/contact", "/test"], stats.pluck(:pathname).sort
  end

  test "ordered_by_date orders descending" do
    create_daily_stat(sites(:my_blog), hostname: "a.com", date: @date)
    create_daily_stat(sites(:my_blog), hostname: "b.com", date: @date + 1.day)
    create_daily_stat(sites(:my_blog), hostname: "c.com", date: @date - 1.day)

    stats = DailyPageStat.ordered_by_date

    assert_equal ["b.com", "a.com", "c.com"], stats.pluck(:hostname)
  end
end
