# frozen_string_literal: true

require "test_helper"
require "support/shared_stat_tests"

class HourlyPageStatTest < ActiveSupport::TestCase
  include SharedStatTests

  setup do
    @time_bucket = Time.zone.parse("2026-03-28 14:00:00")
  end

  def stat_class
    HourlyPageStat
  end

  def create_stat(site, **attrs)
    attrs[:time_bucket] ||= @time_bucket
    create_hourly_stat(site, **attrs)
  end

  test "for_date_range scope filters by time_bucket" do
    create_hourly_stat(sites(:my_blog), pathname: "/test", time_bucket: @time_bucket)

    assert_equal 1, HourlyPageStat.for_date_range(@time_bucket - 1.hour, @time_bucket + 1.hour).count
    assert_equal 0, HourlyPageStat.for_date_range(@time_bucket + 2.hours, @time_bucket + 3.hours).count
  end

  test "for_date_range scope filters by start_time only" do
    create_hourly_stat(sites(:my_blog), pathname: "/test", time_bucket: @time_bucket)
    create_hourly_stat(sites(:my_blog), pathname: "/about", time_bucket: @time_bucket + 1.hour)
    create_hourly_stat(sites(:my_blog), pathname: "/contact", time_bucket: @time_bucket - 1.hour)

    stats = HourlyPageStat.for_date_range(@time_bucket, nil)

    assert_equal 2, stats.count
    assert_equal ["/about", "/test"], stats.pluck(:pathname).sort
  end

  test "for_date_range scope filters by end_time only" do
    create_hourly_stat(sites(:my_blog), pathname: "/test", time_bucket: @time_bucket)
    create_hourly_stat(sites(:my_blog), pathname: "/about", time_bucket: @time_bucket + 1.hour)
    create_hourly_stat(sites(:my_blog), pathname: "/contact", time_bucket: @time_bucket - 1.hour)

    stats = HourlyPageStat.for_date_range(nil, @time_bucket)

    assert_equal 2, stats.count
    assert_equal ["/contact", "/test"], stats.pluck(:pathname).sort
  end

  test "ordered_by_time orders descending" do
    create_hourly_stat(sites(:my_blog), hostname: "a.com", time_bucket: @time_bucket)
    create_hourly_stat(sites(:my_blog), hostname: "b.com", time_bucket: @time_bucket + 1.hour)
    create_hourly_stat(sites(:my_blog), hostname: "c.com", time_bucket: @time_bucket - 1.hour)

    stats = HourlyPageStat.ordered_by_time

    assert_equal ["b.com", "a.com", "c.com"], stats.pluck(:hostname)
  end

  test "older_than scope filters by time_bucket" do
    create_hourly_stat(sites(:my_blog), hostname: "old.com", time_bucket: @time_bucket - 10.days)
    create_hourly_stat(sites(:my_blog), hostname: "recent.com", time_bucket: @time_bucket)

    cutoff = @time_bucket - 5.days
    stats = HourlyPageStat.older_than(cutoff)

    assert_equal 1, stats.count
    assert_equal "old.com", stats.first.hostname
  end

  test "older_than scope excludes stats at or after cutoff" do
    create_hourly_stat(sites(:my_blog), hostname: "a.com", time_bucket: @time_bucket - 10.days)
    create_hourly_stat(sites(:my_blog), hostname: "b.com", time_bucket: @time_bucket - 5.days)
    create_hourly_stat(sites(:my_blog), hostname: "c.com", time_bucket: @time_bucket)

    cutoff = @time_bucket - 5.days
    stats = HourlyPageStat.older_than(cutoff)

    assert_equal 1, stats.count
    assert_equal ["a.com"], stats.pluck(:hostname)
  end
end
