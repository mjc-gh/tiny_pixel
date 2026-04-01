# frozen_string_literal: true

require "test_helper"

class StatsTableComponentTest < ViewComponent::TestCase
  setup do
    @site = sites(:tech_blog)
  end

  def test_renders_table_with_stats
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

  def test_renders_pathname_column
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

  def test_renders_empty_state_when_no_stats
    columns = [{ label: "Page Views", method: :pageviews }]

    render_inline(StatsTableComponent.new(stats: [], columns: columns, time_column: :date))

    assert_text "No data available for this period."
    assert_no_selector "table"
  end

  def test_formats_daily_time_column
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

  def test_formats_hourly_time_column
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

  def test_formats_weekly_time_column
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

  def test_formats_bounce_rate_with_percentage
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

  def test_formats_avg_duration_with_seconds
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

  def test_renders_pagination_when_provided
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

  def test_does_not_render_pagination_without_all_params
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

  def test_does_not_render_pagination_without_frame_id
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

  private

  def create_paginated_collection(current_page:, total_pages:)
    collection = []
    collection.define_singleton_method(:current_page) { current_page }
    collection.define_singleton_method(:total_pages) { total_pages }
    collection.define_singleton_method(:previous_page) { current_page > 1 ? current_page - 1 : nil }
    collection.define_singleton_method(:next_page) { current_page < total_pages ? current_page + 1 : nil }
    collection
  end
end
