# frozen_string_literal: true

require "test_helper"

class DashboardFiltersComponentTest < ViewComponent::TestCase
  setup do
    @site = sites(:tech_blog)
  end

  test "renders dropdown component" do
    render_inline(DashboardFiltersComponent.new(
      current_interval: "daily",
      start_date: Date.new(2024, 4, 1),
      end_date: Date.new(2024, 4, 24),
      site: @site
    ))

    assert_selector "div[data-controller='dropdown']"
    assert_selector "button[data-action='dropdown#toggle:stop']"
  end

  test "renders display summary with interval and dates" do
    render_inline(DashboardFiltersComponent.new(
      current_interval: "daily",
      start_date: Date.new(2024, 4, 1),
      end_date: Date.new(2024, 4, 24),
      site: @site
    ))

    assert_text "Daily · Apr 1 - Apr 24"
  end

  test "renders display summary with only start_date" do
    render_inline(DashboardFiltersComponent.new(
      current_interval: "daily",
      start_date: Date.new(2024, 4, 1),
      end_date: nil,
      site: @site
    ))

    assert_text "Daily · Apr 1 to now"
  end

  test "renders display summary with only end_date" do
    render_inline(DashboardFiltersComponent.new(
      current_interval: "daily",
      start_date: nil,
      end_date: Date.new(2024, 4, 24),
      site: @site
    ))

    assert_text "Daily · oldest to Apr 24"
  end

  test "renders interval radio buttons" do
    render_inline(DashboardFiltersComponent.new(
      current_interval: "daily",
      start_date: Date.new(2024, 4, 1),
      end_date: Date.new(2024, 4, 24),
      site: @site
    ))

    assert_selector "input[type='radio'][value='hourly']"
    assert_selector "input[type='radio'][value='daily'][checked]"
    assert_selector "input[type='radio'][value='weekly']"
  end

  test "renders selected interval radio as checked" do
    render_inline(DashboardFiltersComponent.new(
      current_interval: "weekly",
      start_date: Date.new(2024, 4, 1),
      end_date: Date.new(2024, 4, 24),
      site: @site
    ))

    assert_selector "input[type='radio'][value='weekly'][checked]"
    assert_no_selector "input[type='radio'][value='daily'][checked]"
  end

  test "renders date range inputs" do
    start_date = Date.new(2024, 4, 1)
    end_date = Date.new(2024, 4, 24)

    render_inline(DashboardFiltersComponent.new(
      current_interval: "daily",
      start_date: start_date,
      end_date: end_date,
      site: @site
    ))

    assert_selector "input[type='date'][name='start_date'][value='#{start_date.iso8601}']"
    assert_selector "input[type='date'][name='end_date'][value='#{end_date.iso8601}']"
  end

  test "renders date inputs with site-dashboard data actions" do
    render_inline(DashboardFiltersComponent.new(
      current_interval: "daily",
      start_date: Date.new(2024, 4, 1),
      end_date: Date.new(2024, 4, 24),
      site: @site
    ))

    assert_selector "input[data-action='change->site-dashboard#updateDateRange']", count: 2
  end

  test "renders interval radio buttons with site-dashboard data actions" do
    render_inline(DashboardFiltersComponent.new(
      current_interval: "daily",
      start_date: Date.new(2024, 4, 1),
      end_date: Date.new(2024, 4, 24),
      site: @site
    ))

    assert_selector "input[type='radio'][data-action='change->site-dashboard#updateInterval']", count: 3
  end

  test "renders dropdown menu with data targets" do
    render_inline(DashboardFiltersComponent.new(
      current_interval: "daily",
      start_date: Date.new(2024, 4, 1),
      end_date: Date.new(2024, 4, 24),
      site: @site
    ))

    assert_selector "div[data-dropdown-target='menu']"
  end

  test "renders with nil dates" do
    render_inline(DashboardFiltersComponent.new(
      current_interval: "daily",
      start_date: nil,
      end_date: nil,
      site: @site
    ))

    assert_selector "button", text: /Daily · Date range/
    assert_selector "input[type='date'][name='start_date'][value='']"
    assert_selector "input[type='date'][name='end_date'][value='']"
  end

  test "renders all interval labels" do
    render_inline(DashboardFiltersComponent.new(
      current_interval: "daily",
      start_date: Date.new(2024, 4, 1),
      end_date: Date.new(2024, 4, 24),
      site: @site
    ))

    assert_text "Hourly"
    assert_text "Daily"
    assert_text "Weekly"
  end
end
