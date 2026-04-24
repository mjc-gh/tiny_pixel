# frozen_string_literal: true

require "test_helper"

class StatsTableComponentTest < ViewComponent::TestCase
  setup do
    @site = sites(:tech_blog)
  end

  test "renders table with stats" do
    stat = DailyPageStat.create!(
      site: @site,
      hostname: "example.com",
      pathname: "/",
      date: Date.current,
      pageviews: 100,
      unique_pageviews: 80
    )
    columns = [
      { label: "Page Views", method: :pageviews },
      { label: "Unique Page Views", method: :unique_pageviews }
    ]

    render_inline(StatsTableComponent.new(stats: [stat], columns: columns, time_column: :date))

    assert_selector "table"
    assert_selector "th", text: "Time"
    assert_selector "th", text: "Pathname"
    assert_selector "th", text: "Page Views"
    assert_selector "th", text: "Unique Page Views"
  end

  test "renders pathname column" do
    stat = DailyPageStat.create!(
      site: @site,
      hostname: "example.com",
      pathname: "/test-path",
      date: Date.current,
      pageviews: 100
    )
    columns = [{ label: "Page Views", method: :pageviews }]

    render_inline(StatsTableComponent.new(stats: [stat], columns: columns, time_column: :date))

    assert_text "/test-path"
  end

  test "renders empty state when no stats" do
    columns = [{ label: "Page Views", method: :pageviews }]

    render_inline(StatsTableComponent.new(stats: [], columns: columns, time_column: :date))

    assert_text "No data available for this period."
    assert_no_selector "table"
  end

  test "formats daily time column" do
    stat = DailyPageStat.create!(
      site: @site,
      hostname: "example.com",
      pathname: "/",
      date: Date.current,
      pageviews: 100
    )
    columns = [{ label: "Page Views", method: :pageviews }]

    render_inline(StatsTableComponent.new(stats: [stat], columns: columns, time_column: :date))

    assert_text Date.current.strftime("%b %d, %Y")
  end

  test "formats hourly time column" do
    stat = HourlyPageStat.create!(
      site: @site,
      hostname: "example.com",
      pathname: "/",
      time_bucket: Time.current.beginning_of_hour,
      pageviews: 100
    )
    columns = [{ label: "Page Views", method: :pageviews }]

    render_inline(StatsTableComponent.new(stats: [stat], columns: columns, time_column: :time_bucket))

    assert_text Time.current.beginning_of_hour.strftime("%Y-%m-%d %H:%M")
  end

  test "formats weekly time column" do
    stat = WeeklyPageStat.create!(
      site: @site,
      hostname: "example.com",
      pathname: "/",
      week_start: Date.current.beginning_of_week,
      pageviews: 100
    )
    columns = [{ label: "Page Views", method: :pageviews }]

    render_inline(StatsTableComponent.new(stats: [stat], columns: columns, time_column: :week_start))

    assert_text "Week of"
  end

  test "formats bounce rate with percentage" do
    stat = DailyPageStat.create!(
      site: @site,
      hostname: "example.com",
      pathname: "/",
      date: Date.current,
      pageviews: 100,
      bounced_count: 25
    )
    columns = [{ label: "Bounce Rate", method: :bounce_rate }]

    render_inline(StatsTableComponent.new(stats: [stat], columns: columns, time_column: :date))

    assert_text "%"
  end

  test "formats avg duration with seconds" do
    stat = DailyPageStat.create!(
      site: @site,
      hostname: "example.com",
      pathname: "/",
      date: Date.current,
      pageviews: 100,
      total_duration: 300.0,
      duration_count: 10
    )
    columns = [{ label: "Avg Duration", method: :avg_duration }]

    render_inline(StatsTableComponent.new(stats: [stat], columns: columns, time_column: :date))

    assert_text "s"
  end

  test "renders pagination when provided" do
    stat = DailyPageStat.create!(
      site: @site,
      hostname: "example.com",
      pathname: "/",
      date: Date.current,
      pageviews: 100
    )
    columns = [{ label: "Page Views", method: :pageviews }]
    pagination = create_paginated_collection(current_page: 1, total_pages: 3)

    render_inline(StatsTableComponent.new(
      stats: [stat],
      columns: columns,
      time_column: :date,
      pagination: pagination,
      frame_id: "test_frame",
      base_path: "/test/path"
    ))

    assert_selector "nav[aria-label='Pagination']"
  end

  test "does not render pagination without all params" do
    stat = DailyPageStat.create!(
      site: @site,
      hostname: "example.com",
      pathname: "/",
      date: Date.current,
      pageviews: 100
    )
    columns = [{ label: "Page Views", method: :pageviews }]

    render_inline(StatsTableComponent.new(
      stats: [stat],
      columns: columns,
      time_column: :date,
      pagination: nil
    ))

    assert_no_selector "nav[aria-label='Pagination']"
  end

  test "does not render pagination without frame id" do
    stat = DailyPageStat.create!(
      site: @site,
      hostname: "example.com",
      pathname: "/",
      date: Date.current,
      pageviews: 100
    )
    columns = [{ label: "Page Views", method: :pageviews }]
    pagination = create_paginated_collection(current_page: 1, total_pages: 3)

    render_inline(StatsTableComponent.new(
      stats: [stat],
      columns: columns,
      time_column: :date,
      pagination: pagination,
      frame_id: nil,
      base_path: "/test/path"
    ))

    assert_no_selector "nav[aria-label='Pagination']"
  end
end
