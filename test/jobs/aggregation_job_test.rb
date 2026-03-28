# frozen_string_literal: true

require "test_helper"

class AggregationJobTest < ActiveSupport::TestCase
  setup do
    @site = sites(:my_blog)
  end

  test "perform delegates to AggregationService.aggregate_all_sites" do
    job = AggregationJob.new
    recent_time = Time.current.beginning_of_hour - 1.hour

    create_test_page_views(recent_time)

    job.perform(lookback_hours: 48)

    assert HourlyPageStat.exists?(site: @site)
  end

  test "perform uses default lookback hours when not specified" do
    job = AggregationJob.new
    recent_time = Time.current.beginning_of_hour - 1.hour

    create_test_page_views(recent_time)

    job.perform

    assert HourlyPageStat.exists?(site: @site)
  end

  private

  def create_test_page_views(time_bucket)
    visitor = Visitor.create!(
      digest: "visitor_digest_job_test",
      property_id: @site.id,
      browser: :chrome,
      device_type: :desktop,
      country: "US",
      salt_version: @site.salt_version
    )

    PageView.create!(
      digest: "pv_digest_job_test",
      visitor_digest: visitor.digest,
      hostname: "example.com",
      pathname: "/job-test",
      created_at: time_bucket + 5.minutes,
      new_visit: true,
      new_session: true,
      is_unique: true,
      bounced: false,
      duration: 30
    )
  end
end
