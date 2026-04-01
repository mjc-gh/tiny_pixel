# frozen_string_literal: true

require "test_helper"

module Sites
  class VisitorsControllerTest < ActionDispatch::IntegrationTest
    test "redirects unauthenticated users to login" do
      get site_visitors_url(sites(:tech_blog))

      assert_redirected_to login_path
    end

    test "authenticated users can access index" do
      login(users(:alice), password: "password123")

      get site_visitors_url(sites(:tech_blog))

      assert_response :success
    end

    test "returns turbo frame with stats" do
      login(users(:alice), password: "password123")

      get site_visitors_url(sites(:tech_blog))

      assert_select "turbo-frame#visitors_stats"
    end

    test "displays visitors data with daily interval" do
      login(users(:alice), password: "password123")
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.current,
        visits: 50,
        sessions: 40
      )

      get site_visitors_url(sites(:tech_blog), interval: "daily", view_mode: "table")

      assert_response :success
      assert_select "table"
    end

    test "displays visitors data with hourly interval" do
      login(users(:alice), password: "password123")

      get site_visitors_url(sites(:tech_blog), interval: "hourly")

      assert_response :success
    end

    test "displays visitors data with weekly interval" do
      login(users(:alice), password: "password123")

      get site_visitors_url(sites(:tech_blog), interval: "weekly")

      assert_response :success
    end

    test "returns 404 for unauthorized site" do
      login(users(:bob), password: "password123")

      get site_visitors_url(sites(:tech_blog))

      assert_response :not_found
    end

    test "allows bob to access my_blog where he is a member" do
      login(users(:bob), password: "password123")

      get site_visitors_url(sites(:my_blog))

      assert_response :success
    end
  end
end
