# frozen_string_literal: true

require "test_helper"

class HourlyEventStatTest < ActiveSupport::TestCase
  test "filters and orders event stats" do
    site = sites(:my_blog)
    create_hourly_event_stat(site, name: "a", hits: 2, time_bucket: 2.hours.ago)
    create_hourly_event_stat(site, name: "b", hits: 5, time_bucket: 1.hour.ago)

    assert_equal ["b", "a"], HourlyEventStat.for_site(site.id).ordered_by_hits.pluck(:name)
    assert_equal 1, HourlyEventStat.for_name("a").for_hostname("example.com").for_pathname("/").count
    assert_equal 1, HourlyEventStat.older_than(90.minutes.ago).count
    assert_equal 2, HourlyEventStat.for_date_range(3.hours.ago, 30.minutes.ago).count
    assert_equal 2, HourlyEventStat.for_date_range(3.hours.ago, nil).count
    assert_equal 2, HourlyEventStat.for_date_range(nil, 30.minutes.from_now).count
    assert_equal 2, HourlyEventStat.for_date_range(nil, nil).count
    assert_equal ["b", "a"], HourlyEventStat.ordered_by_time.pluck(:name)
  end

  private

  def create_hourly_event_stat(site, **attrs)
    HourlyEventStat.create!(site:, name: "event", hostname: "example.com", pathname: "/", **attrs)
  end
end
