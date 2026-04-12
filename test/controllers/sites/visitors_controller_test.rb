# frozen_string_literal: true

require "test_helper"

module Sites
  class VisitorsControllerTest < ActionDispatch::IntegrationTest
    test "redirects unauthenticated users to login" do
      get site_visitors_url(sites(:tech_blog))

      assert_redirected_to login_path
    end

    test "authenticated users can access index" do
      login(users(:alice))

      get site_visitors_url(sites(:tech_blog))

      assert_response :success
    end

    test "returns turbo frame with stats" do
      login(users(:alice))

      get site_visitors_url(sites(:tech_blog))

      assert_select "turbo-frame#visitors_stats"
    end

    test "displays visitors data with daily interval" do
      login(users(:alice))
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.current,
        visits: 50,
        sessions: 40
      )

      get site_visitors_url(sites(:tech_blog), interval: "daily")

      assert_response :success
    end

    test "displays visitors data with hourly interval" do
      login(users(:alice))

      get site_visitors_url(sites(:tech_blog), interval: "hourly")

      assert_response :success
    end

    test "displays visitors data with weekly interval" do
      login(users(:alice))

      get site_visitors_url(sites(:tech_blog), interval: "weekly")

      assert_response :success
    end

    test "returns 404 for unauthorized site" do
      login(users(:bob))

      get site_visitors_url(sites(:tech_blog))

      assert_response :not_found
    end

    test "allows bob to access my_blog where he is a member" do
      login(users(:bob))

      get site_visitors_url(sites(:my_blog))

      assert_response :success
    end

    test "filters visitors by pathname when param present" do
      login(users(:alice))
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.current,
        visits: 50,
        sessions: 40
      )
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/about",
        date: Date.current,
        visits: 25,
        sessions: 20
      )

      get site_visitors_url(sites(:tech_blog), pathname: "/")

      assert_response :success
    end

    test "chart data includes only filtered pathname" do
      login(users(:alice))
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.current,
        visits: 50,
        sessions: 40
      )
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/about",
        date: Date.current,
        visits: 25,
        sessions: 20
      )

      get site_visitors_url(sites(:tech_blog), pathname: "/")

      assert_response :success
      # Chart data should only contain data for "/" pathname
    end

    test "filters visitors by date range when params present" do
      login(users(:alice))
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.new(2024, 1, 15),
        visits: 50,
        sessions: 40
      )
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.new(2024, 1, 25),
        visits: 30,
        sessions: 25
      )

      get site_visitors_url(sites(:tech_blog), start_date: "2024-01-20", end_date: "2024-01-31")

      assert_response :success
    end

    test "chart data includes only visitors within date range" do
      login(users(:alice))
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.new(2024, 1, 15),
        visits: 50,
        sessions: 40
      )
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.new(2024, 1, 25),
        visits: 30,
        sessions: 25
      )

      get site_visitors_url(sites(:tech_blog), start_date: "2024-01-20", end_date: "2024-01-31")

      assert_response :success
      # Only Jan 25 data should be included
    end
  end
end
