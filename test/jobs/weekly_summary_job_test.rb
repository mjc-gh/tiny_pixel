# frozen_string_literal: true

require "test_helper"

class WeeklySummaryJobTest < ActiveJob::TestCase
  test "job skips users with no site memberships" do
    user = User.create!(
      email: "test@example.com",
      password: "password123456"
    )

    assert_no_difference -> { ActionMailer::Base.deliveries.count } do
      WeeklySummaryJob.new.perform
    end
  end

  test "job sends email to users with site memberships" do
    TinyPixel.stub :email_delivery_supported?, true do
      user = User.create!(
        email: "test@example.com",
        password: "password123456"
      )

      site = Site.create!(name: "Test Site")
      Membership.create!(user: user, site: site)

      perform_enqueued_jobs do
        WeeklySummaryJob.new.perform
        # Just verify the job runs without error and performs enqueued jobs
        assert_not_empty ActionMailer::Base.deliveries.select { |m| m.to.include?(user.email) }
      end
    end
  end

  test "job sends email to all users with memberships" do
    TinyPixel.stub :email_delivery_supported?, true do
      user_one = User.create!(
        email: "user1@example.com",
        password: "password123456"
      )

      user_two = User.create!(
        email: "user2@example.com",
        password: "password123456"
      )

      site = Site.create!(name: "Test Site")
      Membership.create!(user: user_one, site: site)
      Membership.create!(user: user_two, site: site)

      perform_enqueued_jobs do
        WeeklySummaryJob.new.perform
        # Verify both users received emails
        assert_not_empty ActionMailer::Base.deliveries.select { |m| m.to.include?(user_one.email) }
        assert_not_empty ActionMailer::Base.deliveries.select { |m| m.to.include?(user_two.email) }
      end
    end
  end

  test "job computes correct stats with valid data" do
    user = User.create!(
      email: "test@example.com",
      password: "password123456"
    )

    site = Site.create!(name: "Test Site")
    Membership.create!(user: user, site: site)

    # Create sample stats from past 7 days (from 7 days ago to 1 day ago)
    # That's 7 different dates
    start_date = 7.days.ago.to_date
    (0..6).each do |offset|
      date = start_date + offset.days
      DailyPageStat.create!(
        site_id: site.id,
        hostname: "example.com",
        pathname: "/page1",
        date: date,
        dimension_type: "global",
        pageviews: 100,
        sessions: 50,
        total_duration: 500.0,
        duration_count: 10
      )
    end

    job = WeeklySummaryJob.new
    site_data = job.send(:compute_site_stats, site)

    # Each day has 100 pageviews, 50 sessions, 500 duration with 10 counts
    # 7 days of data means 700 total / 7 = 100 avg
    assert_equal 100.0, site_data[:avg_daily_pageviews]
    assert_equal 50.0, site_data[:avg_daily_sessions]
    # Duration average: (500 * 7) total_duration / (10 * 7) count = 3500 / 70 = 50
    assert_equal 50.0, site_data[:avg_daily_duration]
  end

  test "job handles sites with no stats" do
    user = User.create!(
      email: "test@example.com",
      password: "password123456"
    )

    site = Site.create!(name: "Test Site")
    Membership.create!(user: user, site: site)

    job = WeeklySummaryJob.new
    site_data = job.send(:compute_site_stats, site)

    assert_equal 0.0, site_data[:avg_daily_pageviews]
    assert_equal 0.0, site_data[:avg_daily_sessions]
    assert_nil site_data[:avg_daily_duration]
    assert_nil site_data[:top_page_by_sessions]
    assert_nil site_data[:top_page_by_duration]
  end

  test "job identifies top page by sessions" do
    job = WeeklySummaryJob.new

    site = Site.create!(name: "Test Site")

    # Create stats for multiple pages
    start_date = 7.days.ago.to_date
    (0..6).each do |offset|
      date = start_date + offset.days

      # Page 1: 100 sessions
      DailyPageStat.create!(
        site_id: site.id,
        hostname: "example.com",
        pathname: "/page1",
        date: date,
        dimension_type: "global",
        pageviews: 100,
        sessions: 100,
        total_duration: 0.0,
        duration_count: 0
      )

      # Page 2: 50 sessions
      DailyPageStat.create!(
        site_id: site.id,
        hostname: "example.com",
        pathname: "/page2",
        date: date,
        dimension_type: "global",
        pageviews: 50,
        sessions: 50,
        total_duration: 0.0,
        duration_count: 0
      )
    end

    site_data = job.send(:compute_site_stats, site)

    assert_equal "/page1", site_data[:top_page_by_sessions][:pathname]
    assert_equal 700, site_data[:top_page_by_sessions][:sessions]
  end

  test "job identifies top page by average duration" do
    job = WeeklySummaryJob.new

    site = Site.create!(name: "Test Site")

    # Create stats for multiple pages
    start_date = 7.days.ago.to_date
    (0..6).each do |offset|
      date = start_date + offset.days

      # Page 1: 10 seconds avg duration
      DailyPageStat.create!(
        site_id: site.id,
        hostname: "example.com",
        pathname: "/page1",
        date: date,
        dimension_type: "global",
        pageviews: 100,
        sessions: 50,
        total_duration: 100.0,
        duration_count: 10
      )

      # Page 2: 20 seconds avg duration
      DailyPageStat.create!(
        site_id: site.id,
        hostname: "example.com",
        pathname: "/page2",
        date: date,
        dimension_type: "global",
        pageviews: 50,
        sessions: 25,
        total_duration: 400.0,
        duration_count: 20
      )
    end

    site_data = job.send(:compute_site_stats, site)

    assert_equal "/page2", site_data[:top_page_by_duration][:pathname]
    assert site_data[:top_page_by_duration][:avg_duration] > 19 && site_data[:top_page_by_duration][:avg_duration] < 21
  end

  test "job handles duration data correctly with no duration count" do
    job = WeeklySummaryJob.new

    site = Site.create!(name: "Test Site")

    start_date = 7.days.ago.to_date
    (0..6).each do |offset|
      date = start_date + offset.days
      DailyPageStat.create!(
        site_id: site.id,
        hostname: "example.com",
        pathname: "/page1",
        date: date,
        dimension_type: "global",
        pageviews: 100,
        sessions: 50,
        total_duration: 0.0,
        duration_count: 0
      )
    end

    site_data = job.send(:compute_site_stats, site)

    assert_nil site_data[:avg_daily_duration]
  end
end
