# frozen_string_literal: true

require "test_helper"

class DimensionTableComponentTest < ViewComponent::TestCase
  [
    ["country", "Countries", "country_stats"],
    ["browser", "Browsers", "browser_stats"],
    ["device_type", "Device Types", "device_type_stats"],
    ["referrer_hostname", "Referrers", "referrer_hostname_stats"]
  ].each do |type, label, frame_id|
    define_method("test_renders_#{type}_label") do
      stats = create_paginated_collection([])
      site = sites(:tech_blog)

      render_inline(DimensionTableComponent.new(
        stats: stats,
        type: type,
        frame_id: frame_id,
        site: site,
        base_path: "/sites/1/dimensions"
      ))

      assert_text label
    end
  end

  def test_renders_table_with_headers
    stats = create_paginated_collection([])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "country",
      frame_id: "country_stats",
      site: site,
      base_path: "/sites/1/dimensions"
    ))

    assert_selector "table"
    assert_selector "thead"
    assert_selector "th", text: /Country|Page Views|Sessions/
  end

  def test_renders_dimension_values_in_table
    stat = { dimension_value: "US", pageviews: 100, sessions: 50 }
    stats = create_paginated_collection([stat])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "country",
      frame_id: "country_stats",
      site: site,
      base_path: "/sites/1/dimensions"
    ))

    assert_selector "td", text: "US"
  end

  def test_renders_pageviews_count
    stat = { dimension_value: "US", pageviews: 1000, sessions: 500 }
    stats = create_paginated_collection([stat])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "country",
      frame_id: "country_stats",
      site: site,
      base_path: "/sites/1/dimensions"
    ))

    assert_selector "td", text: "1,000"
  end

  def test_renders_sessions_count
    stat = { dimension_value: "US", pageviews: 100, sessions: 500 }
    stats = create_paginated_collection([stat])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "country",
      frame_id: "country_stats",
      site: site,
      base_path: "/sites/1/dimensions"
    ))

    assert_selector "td", text: "500"
  end

  def test_renders_unknown_for_blank_dimension_value
    stat = { dimension_value: "", pageviews: 100, sessions: 50 }
    stats = create_paginated_collection([stat])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "country",
      frame_id: "country_stats",
      site: site,
      base_path: "/sites/1/dimensions"
    ))

    assert_selector "td", text: "Unknown"
  end

  def test_renders_unknown_for_nil_dimension_value
    stat = { dimension_value: nil, pageviews: 100, sessions: 50 }
    stats = create_paginated_collection([stat])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "country",
      frame_id: "country_stats",
      site: site,
      base_path: "/sites/1/dimensions"
    ))

    assert_selector "td", text: "Unknown"
  end

  def test_renders_multiple_dimension_values
    stats_data = [
      { dimension_value: "US", pageviews: 100, sessions: 50 },
      { dimension_value: "GB", pageviews: 80, sessions: 40 },
      { dimension_value: "CA", pageviews: 60, sessions: 30 }
    ]
    stats = create_paginated_collection(stats_data)
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "country",
      frame_id: "country_stats",
      site: site,
      base_path: "/sites/1/dimensions"
    ))

    assert_selector "td", text: "US"
    assert_selector "td", text: "GB"
    assert_selector "td", text: "CA"
  end

  def test_renders_pagination_component
    stats_data = (1..6).map { |i| { dimension_value: "C#{i}", pageviews: 100 - i, sessions: 50 - i } }
    stats = create_paginated_collection(stats_data, current_page: 1, total_pages: 2)
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "country",
      frame_id: "country_stats",
      site: site,
      base_path: "/sites/1/dimensions"
    ))

    assert_selector "nav[aria-label='Pagination']"
  end

  def test_renders_page_headers_correctly
    stat = { dimension_value: "chrome", pageviews: 100, sessions: 50 }
    stats = create_paginated_collection([stat])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "browser",
      frame_id: "browser_stats",
      site: site,
      base_path: "/sites/1/dimensions"
    ))

    assert_selector "th", text: "Browser"
    assert_selector "th", text: "Page Views"
    assert_selector "th", text: "Sessions"
  end

  def test_renders_device_type_page_headers_correctly
    stat = { dimension_value: "mobile", pageviews: 100, sessions: 50 }
    stats = create_paginated_collection([stat])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "device_type",
      frame_id: "device_type_stats",
      site: site,
      base_path: "/sites/1/dimensions"
    ))

    assert_selector "th", text: "Device Type"
  end

  def test_renders_referrer_hostname_page_headers_correctly
    stat = { dimension_value: "google.com", pageviews: 100, sessions: 50 }
    stats = create_paginated_collection([stat])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "referrer_hostname",
      frame_id: "referrer_hostname_stats",
      site: site,
      base_path: "/sites/1/dimensions"
    ))

    assert_selector "th", text: "Referrer"
  end

  def test_formats_large_numbers_with_delimiters
    stat = { dimension_value: "US", pageviews: 1000000, sessions: 500000 }
    stats = create_paginated_collection([stat])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "country",
      frame_id: "country_stats",
      site: site,
      base_path: "/sites/1/dimensions"
    ))

    assert_selector "td", text: "1,000,000"
    assert_selector "td", text: "500,000"
  end

  def test_renders_empty_table_with_no_stats
    stats = create_paginated_collection([])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "country",
      frame_id: "country_stats",
      site: site,
      base_path: "/sites/1/dimensions"
    ))

    assert_selector "table"
    assert_selector "thead"
    assert_no_selector "tbody tr"
  end

  [
    ["1", "Chrome"],
    ["4", "Firefox"],
    ["999", "Other"]
  ].each do |value, label|
    define_method("test_formats_browser_enum_#{label.downcase}") do
      stat = { dimension_value: value, pageviews: 100, sessions: 50 }
      stats = create_paginated_collection([stat])
      site = sites(:tech_blog)

      render_inline(DimensionTableComponent.new(
        stats: stats,
        type: "browser",
        frame_id: "browser_stats",
        site: site,
        base_path: "/sites/1/dimensions"
      ))

      assert_selector "td", text: label
    end
  end

  [
    ["1", "Desktop"],
    ["2", "Mobile"],
    ["9", "Crawler"],
    ["10", "Other"]
  ].each do |value, label|
    define_method("test_formats_device_type_enum_#{label.downcase}") do
      stat = { dimension_value: value, pageviews: 100, sessions: 50 }
      stats = create_paginated_collection([stat])
      site = sites(:tech_blog)

      render_inline(DimensionTableComponent.new(
        stats: stats,
        type: "device_type",
        frame_id: "device_type_stats",
        site: site,
        base_path: "/sites/1/dimensions"
      ))

      assert_selector "td", text: label
    end
  end

  def test_handles_unknown_browser_enum_value
    stat = { dimension_value: "555", pageviews: 100, sessions: 50 }
    stats = create_paginated_collection([stat])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "browser",
      frame_id: "browser_stats",
      site: site,
      base_path: "/sites/1/dimensions"
    ))

    assert_selector "td", text: "Unknown"
  end

  def test_handles_unknown_device_type_enum_value
    stat = { dimension_value: "555", pageviews: 100, sessions: 50 }
    stats = create_paginated_collection([stat])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "device_type",
      frame_id: "device_type_stats",
      site: site,
      base_path: "/sites/1/dimensions"
    ))

    assert_selector "td", text: "Unknown"
  end

  def test_renders_unknown_dimension_type_label
    stat = { dimension_value: "value", pageviews: 100, sessions: 50 }
    stats = create_paginated_collection([stat])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "custom_dimension",
      frame_id: "custom_dimension_stats",
      site: site,
      base_path: "/sites/1/dimensions"
    ))

    assert_text "Custom dimension"
  end
end
