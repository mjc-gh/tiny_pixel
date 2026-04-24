# frozen_string_literal: true

require "test_helper"

class StatsChartComponentTest < ViewComponent::TestCase
  test "renders chart with data" do
    chart_data = {
      "Page Views" => { Date.current => 100, Date.current - 1.day => 80 }
    }

    render_inline(StatsChartComponent.new(data: chart_data, time_column: :date, chart_id: "test_chart"))

    assert_selector "div.w-full"
  end

  test "renders empty state when no data" do
    chart_data = {
      "Page Views" => {}
    }

    render_inline(StatsChartComponent.new(data: chart_data, time_column: :date, chart_id: "test_chart"))

    assert_text "No data available for this period."
  end

  test "has data returns true with data" do
    chart_data = {
      "Page Views" => { Date.current => 100 }
    }
    component = StatsChartComponent.new(data: chart_data, time_column: :date, chart_id: "test_chart")

    assert component.has_data?
  end

  test "has data returns false with empty data" do
    chart_data = {
      "Page Views" => {}
    }
    component = StatsChartComponent.new(data: chart_data, time_column: :date, chart_id: "test_chart")

    assert_not component.has_data?
  end

  test "chart data transforms to expected format" do
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

  test "chart options returns day unit for daily" do
    component = StatsChartComponent.new(data: {}, time_column: :date, chart_id: "test_chart")

    options = component.chart_options

    assert_equal "day", options[:library][:scales][:x][:time][:unit]
  end

  test "chart options returns hour unit for hourly" do
    component = StatsChartComponent.new(data: {}, time_column: :time_bucket, chart_id: "test_chart")

    options = component.chart_options

    assert_equal "hour", options[:library][:scales][:x][:time][:unit]
  end

  test "chart options returns week unit for weekly" do
    component = StatsChartComponent.new(data: {}, time_column: :week_start, chart_id: "test_chart")

    options = component.chart_options

    assert_equal "week", options[:library][:scales][:x][:time][:unit]
  end

  test "chart options includes chart id" do
    component = StatsChartComponent.new(data: {}, time_column: :date, chart_id: "unique_chart_id")

    options = component.chart_options

    assert_equal "unique_chart_id", options[:id]
  end
end
