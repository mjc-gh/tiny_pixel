# frozen_string_literal: true

require "test_helper"

class AggregationLogTest < ActiveSupport::TestCase
  setup do
    @site = sites(:my_blog)
    @time_bucket = Time.zone.parse("2026-03-28 14:00:00")
  end

  test "completed? returns false when completed_at is nil" do
    log = AggregationLog.new(completed_at: nil)

    assert_not log.completed?
  end

  test "completed? returns true when completed_at is present" do
    log = AggregationLog.new(completed_at: Time.current)

    assert log.completed?
  end

  test "mark_completed! updates log with completion data" do
    log = AggregationLog.create!(
      site: @site,
      aggregation_type: "hourly",
      time_bucket: @time_bucket
    )

    freeze_time do
      log.mark_completed!(rows_created: 5, rows_updated: 3)

      assert_equal Time.current, log.completed_at
      assert_equal 5, log.rows_created
      assert_equal 3, log.rows_updated
    end
  end

  test "for_site scope filters by site_id" do
    AggregationLog.create!(site: @site, aggregation_type: "hourly", time_bucket: @time_bucket)

    assert_equal 1, AggregationLog.for_site(@site.id).count
    assert_equal 0, AggregationLog.for_site(999).count
  end

  test "for_type scope filters by aggregation_type" do
    AggregationLog.create!(site: @site, aggregation_type: "hourly", time_bucket: @time_bucket)
    AggregationLog.create!(site: @site, aggregation_type: "daily", time_bucket: @time_bucket)

    assert_equal 1, AggregationLog.for_type("hourly").count
    assert_equal 1, AggregationLog.for_type("daily").count
    assert_equal 0, AggregationLog.for_type("weekly").count
  end

  test "recent scope orders by time_bucket descending" do
    AggregationLog.create!(site: @site, aggregation_type: "hourly", time_bucket: @time_bucket)
    AggregationLog.create!(site: @site, aggregation_type: "hourly", time_bucket: @time_bucket + 1.hour)
    AggregationLog.create!(site: @site, aggregation_type: "hourly", time_bucket: @time_bucket - 1.hour)

    logs = AggregationLog.recent

    assert_equal [@time_bucket + 1.hour, @time_bucket, @time_bucket - 1.hour], logs.pluck(:time_bucket)
  end

  test "completed scope filters by completed_at presence" do
    AggregationLog.create!(site: @site, aggregation_type: "hourly", time_bucket: @time_bucket)
    AggregationLog.create!(site: @site, aggregation_type: "hourly", time_bucket: @time_bucket + 1.hour, completed_at: Time.current)

    assert_equal 1, AggregationLog.completed.count
  end
end
