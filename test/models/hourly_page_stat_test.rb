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

  test "ordered_by_time orders descending" do
    create_hourly_stat(sites(:my_blog), hostname: "a.com", time_bucket: @time_bucket)
    create_hourly_stat(sites(:my_blog), hostname: "b.com", time_bucket: @time_bucket + 1.hour)
    create_hourly_stat(sites(:my_blog), hostname: "c.com", time_bucket: @time_bucket - 1.hour)

    stats = HourlyPageStat.ordered_by_time

    assert_equal ["b.com", "a.com", "c.com"], stats.pluck(:hostname)
  end
end
