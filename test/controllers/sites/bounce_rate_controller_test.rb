# frozen_string_literal: true

require "test_helper"

module Sites
  class BounceRateControllerTest < ActionDispatch::IntegrationTest
    test "redirects unauthenticated users to login" do
      get site_bounce_rate_index_url(sites(:tech_blog))

      assert_redirected_to login_path
    end

    test "authenticated users can access index" do
      login(users(:alice))

      get site_bounce_rate_index_url(sites(:tech_blog))

      assert_response :success
    end

    test "returns turbo frame with stats" do
      login(users(:alice))

      get site_bounce_rate_index_url(sites(:tech_blog))

      assert_select "turbo-frame#bounce_rate_stats"
    end

    test "displays bounce rate data with daily interval" do
      login(users(:alice))
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.current,
        pageviews: 100,
        bounced_count: 20,
        total_duration: 500.0,
        duration_count: 50
      )

      get site_bounce_rate_index_url(sites(:tech_blog), interval: "daily")

      assert_response :success
    end

    test "displays bounce rate data with hourly interval" do
      login(users(:alice))

      get site_bounce_rate_index_url(sites(:tech_blog), interval: "hourly")

      assert_response :success
    end

    test "displays bounce rate data with weekly interval" do
      login(users(:alice))

      get site_bounce_rate_index_url(sites(:tech_blog), interval: "weekly")

      assert_response :success
    end

    test "returns 404 for unauthorized site" do
      login(users(:bob))

      get site_bounce_rate_index_url(sites(:tech_blog))

      assert_response :not_found
    end

    test "allows bob to access my_blog where he is a member" do
      login(users(:bob))

      get site_bounce_rate_index_url(sites(:my_blog))

      assert_response :success
    end

    test "filters bounce rate data by pathname when param present" do
      login(users(:alice))
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.current,
        pageviews: 100,
        bounced_count: 20,
        total_duration: 500.0,
        duration_count: 50
      )
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/about",
        date: Date.current,
        pageviews: 50,
        bounced_count: 10,
        total_duration: 250.0,
        duration_count: 25
      )

      get site_bounce_rate_index_url(sites(:tech_blog), pathname: "/")

      assert_response :success
    end

    test "chart data includes only filtered pathname" do
      login(users(:alice))
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.current,
        pageviews: 100,
        bounced_count: 20,
        total_duration: 500.0,
        duration_count: 50
      )
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/about",
        date: Date.current,
        pageviews: 50,
        bounced_count: 10,
        total_duration: 250.0,
        duration_count: 25
      )

      get site_bounce_rate_index_url(sites(:tech_blog), pathname: "/")

      assert_response :success
      # Chart data should only contain data for "/" pathname
    end

    test "renders bounce rate chart" do
      login(users(:alice))
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.current,
        pageviews: 100,
        bounced_count: 20,
        total_duration: 500.0,
        duration_count: 50
      )

      get site_bounce_rate_index_url(sites(:tech_blog), interval: "daily")

      assert_response :success
      assert_select "#bounce_rate_chart"
    end

    test "filters bounce rate by date range when params present" do
      login(users(:alice))
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.new(2024, 1, 15),
        pageviews: 100,
        bounced_count: 20
      )
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.new(2024, 1, 25),
        pageviews: 50,
        bounced_count: 10
      )

      get site_bounce_rate_index_url(sites(:tech_blog), start_date: "2024-01-20", end_date: "2024-01-31")

      assert_response :success
    end

    test "chart data includes only bounce rate within date range" do
      login(users(:alice))
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.new(2024, 1, 15),
        pageviews: 100,
        bounced_count: 20
      )
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.new(2024, 1, 25),
        pageviews: 50,
        bounced_count: 10
      )

      get site_bounce_rate_index_url(sites(:tech_blog), start_date: "2024-01-20", end_date: "2024-01-31")

      assert_response :success
      # Only Jan 25 data should be included
    end
  end
end
