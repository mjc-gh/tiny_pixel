# frozen_string_literal: true

require "test_helper"

class StatsChartComponentTest < ViewComponent::TestCase
  def test_renders_chart_with_data
    chart_data = {
      "Page Views" => { Date.current => 100, Date.current - 1.day => 80 }
    }

    render_inline(StatsChartComponent.new(data: chart_data, time_column: :date, chart_id: "test_chart"))

    assert_selector "div.w-full"
  end

  def test_renders_empty_state_when_no_data
    chart_data = {
      "Page Views" => {}
    }

    render_inline(StatsChartComponent.new(data: chart_data, time_column: :date, chart_id: "test_chart"))

    assert_text "No data available for this period."
  end

  def test_has_data_returns_true_with_data
    chart_data = {
      "Page Views" => { Date.current => 100 }
    }
    component = StatsChartComponent.new(data: chart_data, time_column: :date, chart_id: "test_chart")

    assert component.has_data?
  end

  def test_has_data_returns_false_with_empty_data
    chart_data = {
      "Page Views" => {}
    }
    component = StatsChartComponent.new(data: chart_data, time_column: :date, chart_id: "test_chart")

    assert_not component.has_data?
  end

  def test_chart_data_transforms_to_expected_format
    chart_data = {
      "Page Views" => { Date.current => 100 },
      "Unique Views" => { Date.current => 80 }
    }
    component = StatsChartComponent.new(data: chart_data, time_column: :date, chart_id: "test_chart")

    result = component.chart_data

    assert_equal 2, result.length
    assert_equal "Page Views", result[0][:name]
    assert_equal "Unique Views", result[1][:name]
  end

  def test_chart_options_returns_day_unit_for_daily
    component = StatsChartComponent.new(data: {}, time_column: :date, chart_id: "test_chart")

    options = component.chart_options

    assert_equal "day", options[:library][:scales][:x][:time][:unit]
  end

  def test_chart_options_returns_hour_unit_for_hourly
    component = StatsChartComponent.new(data: {}, time_column: :time_bucket, chart_id: "test_chart")

    options = component.chart_options

    assert_equal "hour", options[:library][:scales][:x][:time][:unit]
  end

  def test_chart_options_returns_week_unit_for_weekly
    component = StatsChartComponent.new(data: {}, time_column: :week_start, chart_id: "test_chart")

    options = component.chart_options

    assert_equal "week", options[:library][:scales][:x][:time][:unit]
  end

  def test_chart_options_includes_chart_id
    component = StatsChartComponent.new(data: {}, time_column: :date, chart_id: "unique_chart_id")

    options = component.chart_options

    assert_equal "unique_chart_id", options[:id]
  end
end
