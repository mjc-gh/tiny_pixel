# frozen_string_literal: true

require "test_helper"

class SitesMailerTest < ActionMailer::TestCase
  test "weekly_summary email has correct recipient" do
    user = User.create!(
      email: "test@example.com",
      password: "password123456"
    )

    sites_data = []

    email = SitesMailer.weekly_summary(user, sites_data)

    assert_equal %w[tiny-pixel@tinypixel.localhost], email.from
    assert_equal [user.email], email.to
  end

  test "weekly_summary email has correct subject" do
    user = User.create!(
      email: "test@example.com",
      password: "password123456"
    )

    sites_data = []

    email = SitesMailer.weekly_summary(user, sites_data)

    assert_equal "Your Weekly Analytics Summary", email.subject
  end

  test "weekly_summary email displays user email" do
    user = User.create!(
      email: "test@example.com",
      password: "password123456"
    )

    sites_data = []

    email = SitesMailer.weekly_summary(user, sites_data)

    assert_includes email.body.encoded, user.email
  end

  test "weekly_summary email renders multiple sites" do
    user = User.create!(
      email: "test@example.com",
      password: "password123456"
    )

    site_one = Site.create!(name: "Site One")
    site_two = Site.create!(name: "Site Two")

    sites_data = [
      {
        site: site_one,
        avg_daily_pageviews: 100.0,
        avg_daily_sessions: 50.0,
        avg_daily_duration: 120.5,
        top_page_by_sessions: { pathname: "/page1", sessions: 100 },
        top_page_by_duration: { pathname: "/page2", avg_duration: 200.0 }
      },
      {
        site: site_two,
        avg_daily_pageviews: 200.0,
        avg_daily_sessions: 75.0,
        avg_daily_duration: 150.5,
        top_page_by_sessions: { pathname: "/blog", sessions: 150 },
        top_page_by_duration: { pathname: "/docs", avg_duration: 300.0 }
      }
    ]

    email = SitesMailer.weekly_summary(user, sites_data)

    assert_includes email.body.encoded, "Site One"
    assert_includes email.body.encoded, "Site Two"
    assert_includes email.body.encoded, "100.0"
    assert_includes email.body.encoded, "200.0"
  end

  test "weekly_summary email displays metrics correctly" do
    user = User.create!(
      email: "test@example.com",
      password: "password123456"
    )

    site = Site.create!(name: "Test Site")

    sites_data = [
      {
        site: site,
        avg_daily_pageviews: 150.5,
        avg_daily_sessions: 45.2,
        avg_daily_duration: 125.3,
        top_page_by_sessions: { pathname: "/blog/post-1", sessions: 230 },
        top_page_by_duration: { pathname: "/docs/guide", avg_duration: 245.8 }
      }
    ]

    email = SitesMailer.weekly_summary(user, sites_data)

    assert_includes email.body.encoded, "Daily Avg Pageviews"
    assert_includes email.body.encoded, "Daily Avg Sessions"
    assert_includes email.body.encoded, "Daily Avg Duration"
    assert_includes email.body.encoded, "Top Performing Pages"
  end

  test "weekly_summary email handles no data scenario" do
    user = User.create!(
      email: "test@example.com",
      password: "password123456"
    )

    site = Site.create!(name: "Test Site")

    sites_data = [
      {
        site: site,
        avg_daily_pageviews: 0.0,
        avg_daily_sessions: 0.0,
        avg_daily_duration: nil,
        top_page_by_sessions: nil,
        top_page_by_duration: nil
      }
    ]

    email = SitesMailer.weekly_summary(user, sites_data)

    assert_includes email.body.encoded, "No analytics data available"
  end

  test "weekly_summary email handles missing duration data" do
    user = User.create!(
      email: "test@example.com",
      password: "password123456"
    )

    site = Site.create!(name: "Test Site")

    sites_data = [
      {
        site: site,
        avg_daily_pageviews: 100.0,
        avg_daily_sessions: 50.0,
        avg_daily_duration: nil,
        top_page_by_sessions: { pathname: "/page1", sessions: 100 },
        top_page_by_duration: nil
      }
    ]

    email = SitesMailer.weekly_summary(user, sites_data)

    assert_includes email.body.encoded, "N/A"
  end

  test "weekly_summary email includes dashboard link" do
    user = User.create!(
      email: "test@example.com",
      password: "password123456"
    )

    sites_data = []

    email = SitesMailer.weekly_summary(user, sites_data)

    assert_includes email.body.encoded, "View Dashboard"
  end

  test "weekly_summary email includes TinyPixel footer" do
    user = User.create!(
      email: "test@example.com",
      password: "password123456"
    )

    sites_data = []

    email = SitesMailer.weekly_summary(user, sites_data)

    assert_includes email.body.encoded, "TinyPixel"
    assert_includes email.body.encoded, "tinypixel.tech"
  end

  test "weekly_summary email uses correct layout" do
    user = User.create!(
      email: "test@example.com",
      password: "password123456"
    )

    sites_data = []

    email = SitesMailer.weekly_summary(user, sites_data)

    assert_includes email.body.encoded, "<svg"
  end
end
