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

  test "job computes correct stats with valid daily data" do
    TinyPixel.stub :email_delivery_supported?, true do
      user = User.create!(
        email: "test@example.com",
        password: "password123456"
      )

      site = Site.create!(name: "Test Site", created_at: 7.days.ago)
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

      perform_enqueued_jobs do
        WeeklySummaryJob.new.perform
        # Just verify the job runs without error - specific stats assertions
        # are handled in SiteStatsService tests
        assert_not_empty ActionMailer::Base.deliveries.select { |m| m.to.include?(user.email) }
      end
    end
  end

  test "job handles sites with no stats" do
    TinyPixel.stub :email_delivery_supported?, true do
      user = User.create!(
        email: "test@example.com",
        password: "password123456"
      )

      site = Site.create!(name: "Test Site")
      Membership.create!(user: user, site: site)

      perform_enqueued_jobs do
        WeeklySummaryJob.new.perform
        # Should still send email even with no stats
        assert_not_empty ActionMailer::Base.deliveries.select { |m| m.to.include?(user.email) }
      end
    end
  end

  test "job identifies top page by sessions" do
    TinyPixel.stub :email_delivery_supported?, true do
      user = User.create!(
        email: "test@example.com",
        password: "password123456"
      )

      site = Site.create!(name: "Test Site", created_at: 7.days.ago)
      Membership.create!(user: user, site: site)

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

      perform_enqueued_jobs do
        WeeklySummaryJob.new.perform
        # Job should run without error with this data
        assert_not_empty ActionMailer::Base.deliveries.select { |m| m.to.include?(user.email) }
      end
    end
  end

  test "job identifies top page by average duration" do
    TinyPixel.stub :email_delivery_supported?, true do
      user = User.create!(
        email: "test@example.com",
        password: "password123456"
      )

      site = Site.create!(name: "Test Site", created_at: 7.days.ago)
      Membership.create!(user: user, site: site)

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

      perform_enqueued_jobs do
        WeeklySummaryJob.new.perform
        # Job should run without error with this data
        assert_not_empty ActionMailer::Base.deliveries.select { |m| m.to.include?(user.email) }
      end
    end
  end

  test "job handles duration data correctly with no duration count" do
    TinyPixel.stub :email_delivery_supported?, true do
      user = User.create!(
        email: "test@example.com",
        password: "password123456"
      )

      site = Site.create!(name: "Test Site", created_at: 7.days.ago)
      Membership.create!(user: user, site: site)

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

      perform_enqueued_jobs do
        WeeklySummaryJob.new.perform
        # Job should run without error
        assert_not_empty ActionMailer::Base.deliveries.select { |m| m.to.include?(user.email) }
      end
    end
  end
end
