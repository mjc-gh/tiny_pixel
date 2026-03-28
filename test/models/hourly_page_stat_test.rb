# frozen_string_literal: true

require "test_helper"

class HourlyPageStatTest < ActiveSupport::TestCase
  setup do
    @site = sites(:my_blog)
    @time_bucket = Time.zone.parse("2026-03-28 14:00:00")
  end

  test "avg_duration returns nil when duration_count is zero" do
    stat = HourlyPageStat.new(total_duration: 0, duration_count: 0)

    assert_nil stat.avg_duration
  end

  test "avg_duration calculates average correctly" do
    stat = HourlyPageStat.new(total_duration: 300, duration_count: 10)

    assert_equal 30.0, stat.avg_duration
  end

  test "bounce_rate returns nil when pageviews is zero" do
    stat = HourlyPageStat.new(bounced_count: 0, pageviews: 0)

    assert_nil stat.bounce_rate
  end

  test "bounce_rate calculates percentage correctly" do
    stat = HourlyPageStat.new(bounced_count: 25, pageviews: 100)

    assert_equal 25.0, stat.bounce_rate
  end

  test "for_site scope filters by site_id" do
    HourlyPageStat.create!(
      site: @site,
      hostname: "example.com",
      pathname: "/test",
      time_bucket: @time_bucket
    )

    assert_equal 1, HourlyPageStat.for_site(@site.id).count
    assert_equal 0, HourlyPageStat.for_site(999).count
  end

  test "for_date_range scope filters by time_bucket" do
    HourlyPageStat.create!(
      site: @site,
      hostname: "example.com",
      pathname: "/test",
      time_bucket: @time_bucket
    )

    assert_equal 1, HourlyPageStat.for_date_range(@time_bucket - 1.hour, @time_bucket + 1.hour).count
    assert_equal 0, HourlyPageStat.for_date_range(@time_bucket + 2.hours, @time_bucket + 3.hours).count
  end

  test "for_hostname scope filters by hostname" do
    HourlyPageStat.create!(
      site: @site,
      hostname: "example.com",
      pathname: "/test",
      time_bucket: @time_bucket
    )

    assert_equal 1, HourlyPageStat.for_hostname("example.com").count
    assert_equal 0, HourlyPageStat.for_hostname("other.com").count
  end

  test "for_pathname scope filters by pathname" do
    HourlyPageStat.create!(
      site: @site,
      hostname: "example.com",
      pathname: "/test",
      time_bucket: @time_bucket
    )

    assert_equal 1, HourlyPageStat.for_pathname("/test").count
    assert_equal 0, HourlyPageStat.for_pathname("/other").count
  end

  test "ordered_by_pageviews orders descending" do
    HourlyPageStat.create!(site: @site, hostname: "a.com", pathname: "/", time_bucket: @time_bucket, pageviews: 10)
    HourlyPageStat.create!(site: @site, hostname: "b.com", pathname: "/", time_bucket: @time_bucket, pageviews: 50)
    HourlyPageStat.create!(site: @site, hostname: "c.com", pathname: "/", time_bucket: @time_bucket, pageviews: 25)

    stats = HourlyPageStat.ordered_by_pageviews

    assert_equal [50, 25, 10], stats.pluck(:pageviews)
  end

  test "ordered_by_time orders descending" do
    HourlyPageStat.create!(site: @site, hostname: "a.com", pathname: "/", time_bucket: @time_bucket)
    HourlyPageStat.create!(site: @site, hostname: "b.com", pathname: "/", time_bucket: @time_bucket + 1.hour)
    HourlyPageStat.create!(site: @site, hostname: "c.com", pathname: "/", time_bucket: @time_bucket - 1.hour)

    stats = HourlyPageStat.ordered_by_time

    assert_equal ["b.com", "a.com", "c.com"], stats.pluck(:hostname)
  end
end
