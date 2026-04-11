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
      # Verify pathnames are displayed (first page should show 20 items)
      assert_select "table"
      assert_select "td", { text: "/page-0", count: 1 }
      assert_select "td", { text: "/page-1", count: 1 }
    end

    test "shows no data message when no stats available" do
      login(users(:alice), password: "password123")

      get site_pathnames_url(sites(:tech_blog), interval: "daily")

      assert_response :success
      assert_select "p", { text: /No data available/ }
    end

    test "does not display hostname column when display_hostname is false" do
      login(users(:alice), password: "password123")
      sites(:tech_blog).update!(display_hostname: false)
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
      assert_select "th", text: "Pathname"
      assert_select "th", { text: "Hostname", count: 0 }
    end

    test "displays hostname column when display_hostname is true" do
      login(users(:alice), password: "password123")
      sites(:tech_blog).update!(display_hostname: true)
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
      assert_select "th", text: "Hostname"
      assert_select "th", text: "Pathname"
      assert_select "td", text: "example.com"
    end

    test "groups stats by hostname and pathname when display_hostname is true" do
      login(users(:alice), password: "password123")
      sites(:tech_blog).update!(display_hostname: true)
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "app.example.com",
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
        hostname: "docs.example.com",
        pathname: "/",
        date: Date.current,
        pageviews: 50,
        unique_pageviews: 25,
        visits: 20,
        sessions: 15,
        bounced_count: 10,
        total_duration: 60.0,
        duration_count: 15
      )

      get site_pathnames_url(sites(:tech_blog), interval: "daily")

      assert_response :success
      # Both hostnames should be displayed as separate rows
      assert_select "td", text: "app.example.com"
      assert_select "td", text: "docs.example.com"
    end

    test "groups stats by pathname only when display_hostname is false" do
      login(users(:alice), password: "password123")
      sites(:tech_blog).update!(display_hostname: false)
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "app.example.com",
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
        hostname: "docs.example.com",
        pathname: "/",
        date: Date.current,
        pageviews: 50,
        unique_pageviews: 25,
        visits: 20,
        sessions: 15,
        bounced_count: 10,
        total_duration: 60.0,
        duration_count: 15
      )

      get site_pathnames_url(sites(:tech_blog), interval: "daily")

      assert_response :success
      # Stats should be aggregated - only one "/" row with combined values
      body = response.body
      slash_count = body.scan("<td class=\"px-4 py-3 text-sm text-content-primary font-medium\">/<\/td>").count
      assert_equal 1, slash_count, "Expected only one aggregated / row"
    end

    test "returns single row when filtering by pathname" do
      login(users(:alice), password: "password123")
      sites(:tech_blog).update!(display_hostname: false)
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
        unique_pageviews: 25,
        visits: 20,
        sessions: 15,
        bounced_count: 10,
        total_duration: 60.0,
        duration_count: 15
      )

      get site_pathnames_url(sites(:tech_blog), interval: "daily", pathname: "/about")

      assert_response :success
      # Only /about should be displayed
      assert_select "td", { text: "/about", count: 1 }
      assert_select "td", { text: "/", count: 0 }
    end

    test "returns single row when filtering by pathname and hostname" do
      login(users(:alice), password: "password123")
      sites(:tech_blog).update!(display_hostname: true)
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
        hostname: "docs.example.com",
        pathname: "/",
        date: Date.current,
        pageviews: 50,
        unique_pageviews: 25,
        visits: 20,
        sessions: 15,
        bounced_count: 10,
        total_duration: 60.0,
        duration_count: 15
      )

      get site_pathnames_url(sites(:tech_blog), interval: "daily", pathname: "/", hostname: "docs.example.com")

      assert_response :success
      # Only docs.example.com with / should be displayed
      assert_select "td", { text: "docs.example.com", count: 1 }
      assert_select "td", { text: "example.com", count: 0 }
      assert_select "td", { text: "/", count: 1 }
    end

    test "returns all pathnames when no filter param" do
      login(users(:alice), password: "password123")
      sites(:tech_blog).update!(display_hostname: false)
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
        unique_pageviews: 25,
        visits: 20,
        sessions: 15,
        bounced_count: 10,
        total_duration: 60.0,
        duration_count: 15
      )

      get site_pathnames_url(sites(:tech_blog), interval: "daily")

      assert_response :success
      # Both pathnames should be displayed
      assert_select "td", { text: "/", count: 1 }
      assert_select "td", { text: "/about", count: 1 }
    end

    test "filters pathnames by date range when params present" do
      login(users(:alice), password: "password123")
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.new(2024, 1, 15),
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
        pathname: "/",
        date: Date.new(2024, 1, 25),
        pageviews: 60,
        unique_pageviews: 30,
        visits: 25,
        sessions: 20,
        bounced_count: 12,
        total_duration: 75.0,
        duration_count: 20
      )

      get site_pathnames_url(sites(:tech_blog), start_date: "2024-01-20", end_date: "2024-01-31")

      assert_response :success
    end

    test "aggregates pathname stats within date range" do
      login(users(:alice), password: "password123")
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.new(2024, 1, 15),
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
        pathname: "/",
        date: Date.new(2024, 1, 25),
        pageviews: 60,
        unique_pageviews: 30,
        visits: 25,
        sessions: 20,
        bounced_count: 12,
        total_duration: 75.0,
        duration_count: 20
      )

      get site_pathnames_url(sites(:tech_blog), start_date: "2024-01-20", end_date: "2024-01-31")

      assert_response :success
      # Only Jan 25 data should be included
      assert_select "table"
    end
  end
end
