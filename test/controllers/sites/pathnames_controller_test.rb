# frozen_string_literal: true

require "test_helper"

module Sites
  class PathnamesControllerTest < ActionDispatch::IntegrationTest
    test "redirects unauthenticated users to login" do
      get site_pathnames_url(sites(:tech_blog))

      assert_redirected_to login_path
    end

    test "authenticated users can access index" do
      login(users(:alice), password: "password123")

      get site_pathnames_url(sites(:tech_blog))

      assert_response :success
    end

    test "returns turbo frame with stats" do
      login(users(:alice), password: "password123")

      get site_pathnames_url(sites(:tech_blog))

      assert_select "turbo-frame#pathname_stats"
    end

    test "displays pathname stats with daily interval" do
      login(users(:alice), password: "password123")
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.current,
        pageviews: 100,
        unique_pageviews: 50,
        visits: 40,
        sessions: 30,
        bounced_count: 20,
        total_duration: 120.5,
        duration_count: 30
      )

      get site_pathnames_url(sites(:tech_blog), interval: "daily")

      assert_response :success
      assert_select "table"
      assert_select "td", { text: "/", count: 1 }
    end

    test "aggregates stats by pathname" do
      login(users(:alice), password: "password123")
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.current,
        pageviews: 100,
        unique_pageviews: 50,
        visits: 40,
        sessions: 30,
        bounced_count: 20,
        total_duration: 120.5,
        duration_count: 30
      )
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/about",
        date: Date.current,
        pageviews: 50,
        unique_pageviews: 30,
        visits: 25,
        sessions: 20,
        bounced_count: 10,
        total_duration: 60.0,
        duration_count: 20
      )

      get site_pathnames_url(sites(:tech_blog), interval: "daily")

      assert_response :success
      assert_select "table"
      # Verify both pathnames are present
      assert_select "td", { text: "/", count: 1 }
      assert_select "td", { text: "/about", count: 1 }
    end

    test "displays pathname stats with hourly interval" do
      login(users(:alice), password: "password123")
      HourlyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        time_bucket: Time.current.change(min: 0, sec: 0),
        pageviews: 100,
        unique_pageviews: 50,
        visits: 40,
        sessions: 30,
        bounced_count: 20,
        total_duration: 120.5,
        duration_count: 30
      )

      get site_pathnames_url(sites(:tech_blog), interval: "hourly")

      assert_response :success
    end

    test "displays pathname stats with weekly interval" do
      login(users(:alice), password: "password123")
      WeeklyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        week_start: Date.current.beginning_of_week,
        pageviews: 100,
        unique_pageviews: 50,
        visits: 40,
        sessions: 30,
        bounced_count: 20,
        total_duration: 120.5,
        duration_count: 30
      )

      get site_pathnames_url(sites(:tech_blog), interval: "weekly")

      assert_response :success
    end

    test "returns 404 for unauthorized site" do
      login(users(:bob), password: "password123")

      get site_pathnames_url(sites(:tech_blog))

      assert_response :not_found
    end

    test "allows bob to access my_blog where he is a member" do
      login(users(:bob), password: "password123")

      get site_pathnames_url(sites(:my_blog))

      assert_response :success
    end

    test "sorts pathnames by pageviews descending" do
      login(users(:alice), password: "password123")
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/low",
        date: Date.current,
        pageviews: 10,
        unique_pageviews: 5,
        visits: 4,
        sessions: 3,
        bounced_count: 2,
        total_duration: 30.0,
        duration_count: 3
      )
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/high",
        date: Date.current,
        pageviews: 100,
        unique_pageviews: 50,
        visits: 40,
        sessions: 30,
        bounced_count: 20,
        total_duration: 120.5,
        duration_count: 30
      )

      get site_pathnames_url(sites(:tech_blog), interval: "daily")

      assert_response :success
      # /high should appear before /low in the table
      body = response.body
      high_pos = body.index("/high")
      low_pos = body.index("/low")
      assert high_pos < low_pos, "Expected /high to appear before /low"
    end

    test "calculates bounce rate correctly" do
      login(users(:alice), password: "password123")
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.current,
        pageviews: 100,
        unique_pageviews: 50,
        visits: 40,
        sessions: 30,
        bounced_count: 50,
        total_duration: 120.5,
        duration_count: 30
      )

      get site_pathnames_url(sites(:tech_blog), interval: "daily")

      assert_response :success
      # 50/100 * 100 = 50.0%
      assert_select "td", { text: "50.0%", count: 1 }
    end

    test "calculates avg duration correctly" do
      login(users(:alice), password: "password123")
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.current,
        pageviews: 100,
        unique_pageviews: 50,
        visits: 40,
        sessions: 30,
        bounced_count: 20,
        total_duration: 120.0,
        duration_count: 10
      )

      get site_pathnames_url(sites(:tech_blog), interval: "daily")

      assert_response :success
      # 120.0 / 10 = 12.0s
      assert_select "td", { text: "12.0s", count: 1 }
    end

    test "handles pagination" do
      login(users(:alice), password: "password123")

      # Create 25 pathnames to test pagination (more than PER_PAGE which is 20)
      25.times do |i|
        DailyPageStat.create!(
          site: sites(:tech_blog),
          hostname: "example.com",
          pathname: "/page-#{i}",
          date: Date.current,
          pageviews: 100 - i,
          unique_pageviews: 50,
          visits: 40,
          sessions: 30,
          bounced_count: 20,
          total_duration: 120.5,
          duration_count: 30
        )
      end

      get site_pathnames_url(sites(:tech_blog), interval: "daily")

      assert_response :success
      # Should have pagination controls
      assert_select "nav[aria-label*='Paginat']" # PaginationComponent renders pagination nav
    end

    test "shows no data message when no stats available" do
      login(users(:alice), password: "password123")

      get site_pathnames_url(sites(:tech_blog), interval: "daily")

      assert_response :success
      assert_select "p", { text: /No data available/ }
    end
  end
end
