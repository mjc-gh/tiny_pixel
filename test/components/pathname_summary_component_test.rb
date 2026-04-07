# frozen_string_literal: true

require "test_helper"

class PathnameSummaryComponentTest < ViewComponent::TestCase
  setup do
    @site = sites(:tech_blog)
  end

  def create_paginated_collection(current_page: 1, total_pages: 3)
    collection = []
    collection.define_singleton_method(:current_page) { current_page }
    collection.define_singleton_method(:total_pages) { total_pages }
    collection.define_singleton_method(:previous_page) { current_page > 1 ? current_page - 1 : nil }
    collection.define_singleton_method(:next_page) { current_page < total_pages ? current_page + 1 : nil }
    collection
  end

  def create_stat(hostname: "example.com", pathname: "/", pageviews: 100)
    DailyPageStat.create!(
      site: @site,
      hostname: hostname,
      pathname: pathname,
      date: Date.current,
      pageviews: pageviews,
      unique_pageviews: 50,
      visits: 40,
      sessions: 30,
      bounced_count: 20,
      total_duration: 120.5,
      duration_count: 30
    )
  end

  def build_pageview_stat(pathname:, pageviews:, hostname: nil)
    if hostname
      Sites::PathnamesController::PageviewStat.new(
        hostname: hostname,
        pathname: pathname,
        pageviews: pageviews,
        unique_pageviews: 50,
        visits: 40,
        sessions: 30,
        bounced_count: 20,
        total_duration: 120.5,
        duration_count: 30
      )
    else
      Sites::PathnamesController::PageviewStat.new(
        pathname: pathname,
        pageviews: pageviews,
        unique_pageviews: 50,
        visits: 40,
        sessions: 30,
        bounced_count: 20,
        total_duration: 120.5,
        duration_count: 30
      )
    end
  end

  test "renders table with pathname column by default" do
    stat = build_pageview_stat(pathname: "/", pageviews: 100)

    render_inline(PathnameSummaryComponent.new(stats: [stat]))

    assert_selector "table"
    assert_selector "th", text: "Pathname"
    assert_selector "td", text: "/"
  end

  test "does not render hostname column by default" do
    stat = build_pageview_stat(pathname: "/", pageviews: 100, hostname: "example.com")

    render_inline(PathnameSummaryComponent.new(stats: [stat]))

    assert_selector "th", text: "Pathname"
    assert_no_selector "th", text: "Hostname"
  end

  test "renders hostname column when display_hostname is true" do
    stat = build_pageview_stat(pathname: "/", pageviews: 100, hostname: "example.com")

    render_inline(PathnameSummaryComponent.new(stats: [stat], display_hostname: true))

    assert_selector "th", text: "Hostname"
    assert_selector "th", text: "Pathname"
  end

  test "displays hostname values in table when display_hostname is true" do
    stat = build_pageview_stat(pathname: "/", pageviews: 100, hostname: "app.example.com")

    render_inline(PathnameSummaryComponent.new(stats: [stat], display_hostname: true))

    assert_selector "td", text: "app.example.com"
    assert_selector "td", text: "/"
  end

  test "displays multiple hostnames with display_hostname true" do
    stat_one = build_pageview_stat(pathname: "/", pageviews: 100, hostname: "app.example.com")
    stat_two = build_pageview_stat(pathname: "/", pageviews: 80, hostname: "docs.example.com")

    render_inline(PathnameSummaryComponent.new(stats: [stat_one, stat_two], display_hostname: true))

    assert_selector "td", text: "app.example.com"
    assert_selector "td", text: "docs.example.com"
  end

  test "renders all metric columns" do
    stat = build_pageview_stat(pathname: "/", pageviews: 100)

    render_inline(PathnameSummaryComponent.new(stats: [stat]))

    assert_selector "th", text: "Page Views"
    assert_selector "th", text: "Unique Page Views"
    assert_selector "th", text: "Visits"
    assert_selector "th", text: "Sessions"
    assert_selector "th", text: "Bounce Rate"
    assert_selector "th", text: "Avg Duration"
  end

  test "formats numeric values with delimiters" do
    stat = build_pageview_stat(pathname: "/", pageviews: 1000)

    render_inline(PathnameSummaryComponent.new(stats: [stat]))

    assert_selector "td", text: "1,000"
  end

  test "formats bounce rate with percentage" do
    stat = Sites::PathnamesController::PageviewStat.new(
      pathname: "/",
      pageviews: 100,
      unique_pageviews: 50,
      visits: 40,
      sessions: 30,
      bounced_count: 50,
      total_duration: 120.5,
      duration_count: 30
    )

    render_inline(PathnameSummaryComponent.new(stats: [stat]))

    assert_selector "td", text: "50.0%"
  end

  test "formats avg duration with seconds" do
    stat = Sites::PathnamesController::PageviewStat.new(
      pathname: "/",
      pageviews: 100,
      unique_pageviews: 50,
      visits: 40,
      sessions: 30,
      bounced_count: 20,
      total_duration: 120.0,
      duration_count: 10
    )

    render_inline(PathnameSummaryComponent.new(stats: [stat]))

    assert_selector "td", text: "12.0s"
  end

  test "renders empty state when no stats" do
    render_inline(PathnameSummaryComponent.new(stats: []))

    assert_text "No data available for this period."
    assert_no_selector "table"
  end

  test "renders pagination when provided with all required params" do
    stat = build_pageview_stat(pathname: "/", pageviews: 100)
    pagination = create_paginated_collection(current_page: 1, total_pages: 3)

    render_inline(PathnameSummaryComponent.new(
      stats: [stat],
      pagination: pagination,
      frame_id: "test_frame",
      base_path: "/test/path"
    ))

    assert_selector "nav[aria-label='Pagination']"
  end

  test "does not render pagination without frame_id" do
    stat = build_pageview_stat(pathname: "/", pageviews: 100)
    pagination = create_paginated_collection(current_page: 1, total_pages: 3)

    render_inline(PathnameSummaryComponent.new(
      stats: [stat],
      pagination: pagination,
      frame_id: nil,
      base_path: "/test/path"
    ))

    assert_no_selector "nav[aria-label='Pagination']"
  end
end
