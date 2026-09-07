# frozen_string_literal: true

require "test_helper"

class DailyEventStatTest < ActiveSupport::TestCase
  test "provides date and retention scopes" do
    site = sites(:my_blog)
    DailyEventStat.create!(site:, name: "event", hostname: "example.com", pathname: "/", date: 2.days.ago, hits: 1)
    assert_equal 1, DailyEventStat.for_date_range(3.days.ago.to_date, 2.days.ago.to_date).ordered_by_date.count
    assert_equal 1, DailyEventStat.older_than(1.day.ago).count
    assert_equal 1, DailyEventStat.for_date_range(3.days.ago.to_date, 2.days.ago.to_date).count
    assert_equal 1, DailyEventStat.for_date_range(3.days.ago.to_date, nil).count
    assert_equal 1, DailyEventStat.for_date_range(nil, 2.days.ago.to_date).count
    assert_equal 1, DailyEventStat.for_date_range(nil, nil).count
    assert_equal 1, DailyEventStat.for_name("event").for_hostname("example.com").for_pathname("/").ordered_by_hits.count
  end
end
