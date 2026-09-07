# frozen_string_literal: true

require "test_helper"

class WeeklyEventStatTest < ActiveSupport::TestCase
  test "provides week ordering and retention scopes" do
    site = sites(:my_blog)
    week = Date.current.beginning_of_week(:monday)
    WeeklyEventStat.create!(site:, name: "event", hostname: "example.com", pathname: "/", week_start: week, hits: 1)
    assert_equal 1, WeeklyEventStat.for_date_range(week, week).ordered_by_week.count
    assert_equal 0, WeeklyEventStat.older_than(week).count
    assert_equal 1, WeeklyEventStat.for_date_range(week, nil).count
    assert_equal 1, WeeklyEventStat.for_date_range(nil, week).count
    assert_equal 1, WeeklyEventStat.for_date_range(nil, nil).count
    assert_equal 1, WeeklyEventStat.for_name("event").for_hostname("example.com").for_pathname("/").ordered_by_hits.count
  end
end
