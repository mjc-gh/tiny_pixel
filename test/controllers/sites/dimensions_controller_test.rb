# frozen_string_literal: true

require "test_helper"

module Sites
  class DimensionsControllerTest < ActionDispatch::IntegrationTest
    test "redirects unauthenticated users to login" do
      get site_dimensions_url(sites(:tech_blog), dimension_type: "country")

      assert_redirected_to login_path
    end

    test "authenticated users can access index" do
      login(users(:alice), password: "password123")

      get site_dimensions_url(sites(:tech_blog), dimension_type: "country")

      assert_response :success
    end

    test "returns 404 for invalid dimension type" do
      login(users(:alice), password: "password123")

      get site_dimensions_url(sites(:tech_blog), dimension_type: "invalid_type")

      assert_response :bad_request
    end

    test "returns turbo frame with country dimension stats" do
      login(users(:alice), password: "password123")

      get site_dimensions_url(sites(:tech_blog), dimension_type: "country")

      assert_select "turbo-frame#country_stats"
    end

    test "returns turbo frame with browser dimension stats" do
      login(users(:alice), password: "password123")

      get site_dimensions_url(sites(:tech_blog), dimension_type: "browser")

      assert_select "turbo-frame#browser_stats"
    end

    test "returns turbo frame with device_type dimension stats" do
      login(users(:alice), password: "password123")

      get site_dimensions_url(sites(:tech_blog), dimension_type: "device_type")

      assert_select "turbo-frame#device_type_stats"
    end

    test "returns turbo frame with referrer_hostname dimension stats" do
      login(users(:alice), password: "password123")

      get site_dimensions_url(sites(:tech_blog), dimension_type: "referrer_hostname")

      assert_select "turbo-frame#referrer_hostname_stats"
    end

    test "returns 404 for unauthorized site" do
      login(users(:bob), password: "password123")

      get site_dimensions_url(sites(:tech_blog), dimension_type: "country")

      assert_response :not_found
    end

    test "allows bob to access my_blog where he is a member" do
      login(users(:bob), password: "password123")

      get site_dimensions_url(sites(:my_blog), dimension_type: "country")

      assert_response :success
    end

    test "displays dimension data with daily interval" do
      login(users(:alice), password: "password123")
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.current,
        dimension_type: "country",
        dimension_value: "US",
        pageviews: 100,
        sessions: 50
      )

      get site_dimensions_url(sites(:tech_blog), dimension_type: "country", interval: "daily")

      assert_response :success
      assert_select "td", text: "US"
      assert_select "td", text: "100"
      assert_select "td", text: "50"
    end

    test "displays dimension data with hourly interval" do
      login(users(:alice), password: "password123")

      get site_dimensions_url(sites(:tech_blog), dimension_type: "country", interval: "hourly")

      assert_response :success
    end

    test "displays dimension data with weekly interval" do
      login(users(:alice), password: "password123")

      get site_dimensions_url(sites(:tech_blog), dimension_type: "country", interval: "weekly")

      assert_response :success
    end

    test "filters dimension data by pathname when param present" do
      login(users(:alice), password: "password123")
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.current,
        dimension_type: "country",
        dimension_value: "US",
        pageviews: 100,
        sessions: 50
      )
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/about",
        date: Date.current,
        dimension_type: "country",
        dimension_value: "GB",
        pageviews: 80,
        sessions: 40
      )

      get site_dimensions_url(sites(:tech_blog), dimension_type: "country", pathname: "/")

      assert_response :success
    end

    test "filters dimension data by hostname when param present" do
      login(users(:alice), password: "password123")
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.current,
        dimension_type: "country",
        dimension_value: "US",
        pageviews: 100,
        sessions: 50
      )
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "other.com",
        pathname: "/",
        date: Date.current,
        dimension_type: "country",
        dimension_value: "GB",
        pageviews: 80,
        sessions: 40
      )

      get site_dimensions_url(sites(:tech_blog), dimension_type: "country", hostname: "example.com")

      assert_response :success
    end

    test "filters dimension data by date range when params present" do
      login(users(:alice), password: "password123")
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.new(2024, 1, 15),
        dimension_type: "country",
        dimension_value: "US",
        pageviews: 100,
        sessions: 50
      )
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.new(2024, 1, 25),
        dimension_type: "country",
        dimension_value: "GB",
        pageviews: 80,
        sessions: 40
      )

      get site_dimensions_url(sites(:tech_blog), dimension_type: "country", start_date: "2024-01-20", end_date: "2024-01-31")

      assert_response :success
    end

    test "paginates results to 5 per page" do
      login(users(:alice), password: "password123")

      10.times do |i|
        DailyPageStat.create!(
          site: sites(:tech_blog),
          hostname: "example.com",
          pathname: "/",
          date: Date.current,
          dimension_type: "country",
          dimension_value: "C#{i}",
          pageviews: 100 - i,
          sessions: 50 - i
        )
      end

      get site_dimensions_url(sites(:tech_blog), dimension_type: "country", page: 1)

      assert_response :success
    end

    test "displays pagination when more than 5 results" do
      login(users(:alice), password: "password123")

      6.times do |i|
        DailyPageStat.create!(
          site: sites(:tech_blog),
          hostname: "example.com",
          pathname: "/",
          date: Date.current,
          dimension_type: "country",
          dimension_value: "C#{i}",
          pageviews: 100 - i,
          sessions: 50 - i
        )
      end

      get site_dimensions_url(sites(:tech_blog), dimension_type: "country")

      assert_response :success
      assert_select "nav[aria-label='Pagination']"
    end

    test "respects page parameter for pagination" do
      login(users(:alice), password: "password123")

      10.times do |i|
        DailyPageStat.create!(
          site: sites(:tech_blog),
          hostname: "example.com",
          pathname: "/",
          date: Date.current,
          dimension_type: "country",
          dimension_value: "C#{i}",
          pageviews: 100 - i,
          sessions: 50 - i
        )
      end

      get site_dimensions_url(sites(:tech_blog), dimension_type: "country", page: 2)

      assert_response :success
    end

    test "aggregates stats by dimension value" do
      login(users(:alice), password: "password123")
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.new(2024, 1, 15),
        dimension_type: "country",
        dimension_value: "US",
        pageviews: 100,
        sessions: 50
      )
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/about",
        date: Date.new(2024, 1, 15),
        dimension_type: "country",
        dimension_value: "US",
        pageviews: 50,
        sessions: 25
      )

      get site_dimensions_url(sites(:tech_blog), dimension_type: "country")

      assert_response :success
      # Stats for same dimension_value should be aggregated
      assert_select "td", text: "150"  # 100 + 50
      assert_select "td", text: "75"   # 50 + 25
    end

    test "orders results by page views descending" do
      login(users(:alice), password: "password123")
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.current,
        dimension_type: "country",
        dimension_value: "US",
        pageviews: 50,
        sessions: 25
      )
      DailyPageStat.create!(
        site: sites(:tech_blog),
        hostname: "example.com",
        pathname: "/",
        date: Date.current,
        dimension_type: "country",
        dimension_value: "GB",
        pageviews: 100,
        sessions: 50
      )

      get site_dimensions_url(sites(:tech_blog), dimension_type: "country")

      assert_response :success
      # GB should appear before US since it has more pageviews
    end
  end
end
