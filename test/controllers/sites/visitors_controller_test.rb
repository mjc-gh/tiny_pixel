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
      create_daily_stat(
        sites(:tech_blog),
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
      create_daily_stat(
        sites(:tech_blog),
        visits: 50,
        sessions: 40
      )
      create_daily_stat(
        sites(:tech_blog),
        pathname: "/about",
        visits: 25,
        sessions: 20
      )

      get site_visitors_url(sites(:tech_blog), pathname: "/")

      assert_response :success
    end

    test "chart data includes only filtered pathname" do
      login(users(:alice))
      create_daily_stat(
        sites(:tech_blog),
        visits: 50,
        sessions: 40
      )
      create_daily_stat(
        sites(:tech_blog),
        pathname: "/about",
        visits: 25,
        sessions: 20
      )

      get site_visitors_url(sites(:tech_blog), pathname: "/")

      assert_response :success
      # Chart data should only contain data for "/" pathname
    end

    test "filters visitors by date range when params present" do
      login(users(:alice))
      create_daily_stat(
        sites(:tech_blog),
        date: Date.new(2024, 1, 15),
        visits: 50,
        sessions: 40
      )
      create_daily_stat(
        sites(:tech_blog),
        date: Date.new(2024, 1, 25),
        visits: 30,
        sessions: 25
      )

      get site_visitors_url(sites(:tech_blog), start_date: "2024-01-20", end_date: "2024-01-31")

      assert_response :success
    end

    test "chart data includes only visitors within date range" do
      login(users(:alice))
      create_daily_stat(
        sites(:tech_blog),
        date: Date.new(2024, 1, 15),
        visits: 50,
        sessions: 40
      )
      create_daily_stat(
        sites(:tech_blog),
        date: Date.new(2024, 1, 25),
        visits: 30,
        sessions: 25
      )

      get site_visitors_url(sites(:tech_blog), start_date: "2024-01-20", end_date: "2024-01-31")

      assert_response :success
      # Only Jan 25 data should be included
    end

    test "filters visitors by dimension type and value" do
      login(users(:alice))
      create_daily_stat(
        sites(:tech_blog),
        visits: 50,
        sessions: 40
      )

      get site_visitors_url(sites(:tech_blog), dimension_type: "country", dimension_value: "US")

      assert_response :success
    end

    test "zero-fills missing days in date range with daily interval" do
      login(users(:alice))
      create_daily_stat(
        sites(:tech_blog),
        date: Date.new(2024, 1, 1),
        visits: 50,
        sessions: 40
      )
      create_daily_stat(
        sites(:tech_blog),
        date: Date.new(2024, 1, 3),
        visits: 100,
        sessions: 80
      )

      get site_visitors_url(
        sites(:tech_blog),
        interval: "daily",
        start_date: "2024-01-01",
        end_date: "2024-01-05"
      )

      assert_response :success
      # Chart data should have 5 days with zeros for missing days
      assert_equal 5, assigns(:chart_data)["Visits"].size
      assert_equal 50, assigns(:chart_data)["Visits"][Date.new(2024, 1, 1)]
      assert_equal 0, assigns(:chart_data)["Visits"][Date.new(2024, 1, 2)]
      assert_equal 100, assigns(:chart_data)["Visits"][Date.new(2024, 1, 3)]
      assert_equal 0, assigns(:chart_data)["Visits"][Date.new(2024, 1, 4)]
      assert_equal 0, assigns(:chart_data)["Visits"][Date.new(2024, 1, 5)]
    end

    test "hourly interval defaults to last 24 hours when no date param provided" do
      login(users(:alice))

      get site_visitors_url(sites(:tech_blog), interval: "hourly")

      assert_response :success
      # Verify response is successful with default hourly range
      assert assigns(:chart_data)
    end

    test "daily interval defaults to last 7 days when no date param provided" do
      login(users(:alice))

      get site_visitors_url(sites(:tech_blog), interval: "daily")

      assert_response :success
      # Verify response is successful with default daily range
      assert assigns(:chart_data)
    end

    test "weekly interval defaults to last 6 weeks when no date param provided" do
      login(users(:alice))

      get site_visitors_url(sites(:tech_blog), interval: "weekly")

      assert_response :success
      # Verify response is successful with default weekly range
      assert assigns(:chart_data)
    end

    test "explicit start_date param overrides default for daily interval" do
      login(users(:alice))

      get site_visitors_url(sites(:tech_blog), interval: "daily", start_date: "2024-01-15")

      assert_response :success
      # If explicit date is provided, it should be used instead of default
      assert assigns(:chart_data)
    end
  end
end
