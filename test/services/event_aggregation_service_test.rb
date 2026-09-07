# frozen_string_literal: true

require "test_helper"

class EventAggregationServiceTest < ActiveSupport::TestCase
  setup do
    @site = sites(:my_blog)
    @other_site = sites(:tech_blog)
    @time_bucket = Time.zone.parse("2026-03-28 14:00:00")
    @service = EventAggregationService.new(@site)
  end

  test "aggregates hits and distinct visitors by event dimensions" do
    create_event("signup", "visitor-1", @time_bucket + 5.minutes)
    create_event("signup", "visitor-1", @time_bucket + 10.minutes)
    create_event("signup", "visitor-2", @time_bucket + 20.minutes)
    create_event("purchase", "visitor-1", @time_bucket + 20.minutes)
    create_event("signup", "visitor-1", @time_bucket + 1.hour)

    result = @service.aggregate_hourly(@time_bucket + 30.minutes)

    assert_equal({ created: 2, updated: 0 }, result)
    stat = HourlyEventStat.find_by(site: @site, name: "signup")
    assert_equal 3, stat.hits
    assert_equal 2, stat.unique_hits
    assert_equal 2, HourlyEventStat.count
  end

  test "calculates daily and weekly uniqueness directly from raw events" do
    create_event("signup", "visitor-1", @time_bucket + 5.minutes)
    create_event("signup", "visitor-1", @time_bucket + 1.day)
    create_event("signup", "visitor-2", @time_bucket + 1.day)

    @service.aggregate_daily(@time_bucket.to_date)
    @service.aggregate_daily((@time_bucket + 1.day).to_date)
    @service.aggregate_weekly(@time_bucket.to_date)

    assert_equal [1, 2], DailyEventStat.order(:date).pluck(:hits)
    assert_equal [1, 2], DailyEventStat.order(:date).pluck(:unique_hits)
    assert_equal 3, WeeklyEventStat.first.hits
    assert_equal 2, WeeklyEventStat.first.unique_hits
  end

  test "isolates sites and removes stale groups on rerun" do
    create_event("signup", "visitor-1", @time_bucket + 5.minutes)
    create_event("signup", "other-visitor", @time_bucket + 5.minutes, site: @other_site)

    @service.aggregate_hourly(@time_bucket)
    assert_equal 1, HourlyEventStat.count

    Event.where(visitor_digest: "visitor-1").delete_all
    result = @service.aggregate_hourly(@time_bucket)

    assert_equal({ created: 0, updated: 0 }, result)
    assert_empty HourlyEventStat.where(site: @site)
    assert_equal 0, HourlyEventStat.where(site: @other_site).count
  end

  test "repeated aggregation updates existing rows" do
    create_event("signup", "visitor-1", @time_bucket + 5.minutes)

    @service.aggregate_hourly(@time_bucket)
    result = @service.aggregate_hourly(@time_bucket)

    assert_equal({ created: 0, updated: 1 }, result)
  end

  private

  def create_event(name, digest, created_at, site: @site)
    Visitor.find_or_create_by!(digest:) do |visitor|
      visitor.assign_attributes(property_id: site.id, browser: :chrome, device_type: :desktop,
        country: "US", salt_version: site.salt_version)
    end
    Event.create!(visitor_digest: digest, name:, hostname: "example.com", pathname: "/signup", created_at:)
  end
end
