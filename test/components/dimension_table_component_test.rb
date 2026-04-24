# frozen_string_literal: true

require "test_helper"

class DimensionTableComponentTest < ViewComponent::TestCase
  def create_stat(hash)
    OpenStruct.new(hash)
  end

  def create_paginated_stats(items)
    stats = items.map { |item| create_stat(item) }
    create_paginated_collection(stats)
  end

  [
    ["country", "Countries", "country_stats"],
    ["browser", "Browsers", "browser_stats"],
    ["device_type", "Device Types", "device_type_stats"],
    ["referrer_hostname", "Referrers", "referrer_hostname_stats"]
  ].each do |type, label, frame_id|
    test "renders #{type} label" do
      stats = create_paginated_stats([])
      site = sites(:tech_blog)

      render_inline(DimensionTableComponent.new(
        stats: stats,
        type: type,
        frame_id: frame_id,
        site: site,
        base_path: "/sites/1/dimensions",
        params: {}
      ))

      assert_text label
    end
  end

  test "renders table with headers" do
    stats = create_paginated_stats([])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "country",
      frame_id: "country_stats",
      site: site,
      base_path: "/sites/1/dimensions",
      params: {}
    ))

    assert_selector "table"
    assert_selector "thead"
    assert_selector "th", text: /Country|Page Views|Sessions/
  end

  test "renders dimension values in table" do
    stat = { dimension_value: "US", pageviews: 100, sessions: 50 }
    stats = create_paginated_stats([stat])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "country",
      frame_id: "country_stats",
      site: site,
      base_path: "/sites/1/dimensions",
      params: {}
    ))

    assert_selector "td", text: "US"
  end

  test "renders pageviews count" do
    stat = { dimension_value: "US", pageviews: 1000, sessions: 500 }
    stats = create_paginated_stats([stat])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "country",
      frame_id: "country_stats",
      site: site,
      base_path: "/sites/1/dimensions",
      params: {}
    ))

    assert_selector "td", text: "1,000"
  end

  test "renders sessions count" do
    stat = { dimension_value: "US", pageviews: 100, sessions: 500 }
    stats = create_paginated_stats([stat])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "country",
      frame_id: "country_stats",
      site: site,
      base_path: "/sites/1/dimensions",
      params: {}
    ))

    assert_selector "td", text: "500"
  end

  test "renders unknown for blank dimension value" do
    stat = { dimension_value: "", pageviews: 100, sessions: 50 }
    stats = create_paginated_stats([stat])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "country",
      frame_id: "country_stats",
      site: site,
      base_path: "/sites/1/dimensions",
      params: {}
    ))

    assert_selector "td", text: "Unknown"
  end

  test "renders unknown for nil dimension value" do
    stat = { dimension_value: nil, pageviews: 100, sessions: 50 }
    stats = create_paginated_stats([stat])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "country",
      frame_id: "country_stats",
      site: site,
      base_path: "/sites/1/dimensions",
      params: {}
    ))

    assert_selector "td", text: "Unknown"
  end

  test "renders multiple dimension values" do
    stats_data = [
      { dimension_value: "US", pageviews: 100, sessions: 50 },
      { dimension_value: "GB", pageviews: 80, sessions: 40 },
      { dimension_value: "CA", pageviews: 60, sessions: 30 }
    ]
    stats = create_paginated_stats(stats_data)
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "country",
      frame_id: "country_stats",
      site: site,
      base_path: "/sites/1/dimensions",
      params: {}
    ))

    assert_selector "td", text: "US"
    assert_selector "td", text: "GB"
    assert_selector "td", text: "CA"
  end

  test "renders pagination component" do
    stats_data = (1..6).map { |i| { dimension_value: "C#{i}", pageviews: 100 - i, sessions: 50 - i } }
    stats = create_paginated_stats(stats_data)
    stats.define_singleton_method(:current_page) { 1 }
    stats.define_singleton_method(:total_pages) { 2 }
    stats.define_singleton_method(:next_page) { 2 }
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "country",
      frame_id: "country_stats",
      site: site,
      base_path: "/sites/1/dimensions",
      params: {}
    ))

    assert_selector "nav[aria-label='Pagination']"
  end

  test "renders page headers correctly" do
    stat = { dimension_value: "chrome", pageviews: 100, sessions: 50 }
    stats = create_paginated_stats([stat])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "browser",
      frame_id: "browser_stats",
      site: site,
      base_path: "/sites/1/dimensions",
      params: {}
    ))

    assert_selector "th", text: "Browser"
    assert_selector "th", text: "Page Views"
    assert_selector "th", text: "Sessions"
  end

  test "renders device type page headers correctly" do
    stat = { dimension_value: "mobile", pageviews: 100, sessions: 50 }
    stats = create_paginated_stats([stat])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "device_type",
      frame_id: "device_type_stats",
      site: site,
      base_path: "/sites/1/dimensions",
      params: {}
    ))

    assert_selector "th", text: "Device Type"
  end

  test "renders referrer hostname page headers correctly" do
    stat = { dimension_value: "google.com", pageviews: 100, sessions: 50 }
    stats = create_paginated_stats([stat])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "referrer_hostname",
      frame_id: "referrer_hostname_stats",
      site: site,
      base_path: "/sites/1/dimensions",
      params: {}
    ))

    assert_selector "th", text: "Referrer"
  end

  test "formats large numbers with delimiters" do
    stat = { dimension_value: "US", pageviews: 1000000, sessions: 500000 }
    stats = create_paginated_stats([stat])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "country",
      frame_id: "country_stats",
      site: site,
      base_path: "/sites/1/dimensions",
      params: {}
    ))

    assert_selector "td", text: "1,000,000"
    assert_selector "td", text: "500,000"
  end

  test "renders empty table with no stats" do
    stats = create_paginated_stats([])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "country",
      frame_id: "country_stats",
      site: site,
      base_path: "/sites/1/dimensions",
      params: {}
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
    test "formats browser enum #{label.downcase}" do
      stat = { dimension_value: value, pageviews: 100, sessions: 50 }
      stats = create_paginated_stats([stat])
      site = sites(:tech_blog)

      render_inline(DimensionTableComponent.new(
        stats: stats,
        type: "browser",
        frame_id: "browser_stats",
        site: site,
        base_path: "/sites/1/dimensions",
        params: {}
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
    test "formats device type enum #{label.downcase}" do
      stat = { dimension_value: value, pageviews: 100, sessions: 50 }
      stats = create_paginated_stats([stat])
      site = sites(:tech_blog)

      render_inline(DimensionTableComponent.new(
        stats: stats,
        type: "device_type",
        frame_id: "device_type_stats",
        site: site,
        base_path: "/sites/1/dimensions",
        params: {}
      ))

      assert_selector "td", text: label
    end
  end

  test "handles unknown browser enum value" do
    stat = { dimension_value: "555", pageviews: 100, sessions: 50 }
    stats = create_paginated_stats([stat])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "browser",
      frame_id: "browser_stats",
      site: site,
      base_path: "/sites/1/dimensions",
      params: {}
    ))

    assert_selector "td", text: "Unknown"
  end

  test "handles unknown device type enum value" do
    stat = { dimension_value: "555", pageviews: 100, sessions: 50 }
    stats = create_paginated_stats([stat])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "device_type",
      frame_id: "device_type_stats",
      site: site,
      base_path: "/sites/1/dimensions",
      params: {}
    ))

    assert_selector "td", text: "Unknown"
  end

  test "renders unknown dimension type label" do
    stat = { dimension_value: "value", pageviews: 100, sessions: 50 }
    stats = create_paginated_stats([stat])
    site = sites(:tech_blog)

    render_inline(DimensionTableComponent.new(
      stats: stats,
      type: "custom_dimension",
      frame_id: "custom_dimension_stats",
      site: site,
      base_path: "/sites/1/dimensions",
      params: {}
    ))

    assert_text "Custom dimension"
  end
end
