# frozen_string_literal: true

require "test_helper"

class TimeSeriesBuilderTest < ActiveSupport::TestCase
  test "returns empty hash when aggregated data is empty and no explicit range" do
    builder = TimeSeriesBuilder.new(interval: "daily")
    result = builder.build([], { "Test" => :value })

    assert_empty result
  end

  test "generates time points with explicit start and end date for daily interval" do
    builder = TimeSeriesBuilder.new(
      interval: "daily",
      start_date: Date.new(2024, 1, 1),
      end_date: Date.new(2024, 1, 5)
    )

    data = []
    result = builder.build(data, { "Test" => :value })

    assert_equal 5, result["Test"].size
    expected_dates = (Date.new(2024, 1, 1)..Date.new(2024, 1, 5)).to_a
    assert_equal expected_dates, result["Test"].keys
  end

  test "fills missing time slots with zeros for daily interval" do
    builder = TimeSeriesBuilder.new(
      interval: "daily",
      start_date: Date.new(2024, 1, 1),
      end_date: Date.new(2024, 1, 5)
    )

    # Create mock data with only some days
    data = [
      MockRow.new(date: Date.new(2024, 1, 1), value: 10),
      MockRow.new(date: Date.new(2024, 1, 3), value: 20)
    ]

    result = builder.build(data, { "Test" => :value })

    assert_equal 10, result["Test"][Date.new(2024, 1, 1)]
    assert_equal 0, result["Test"][Date.new(2024, 1, 2)]
    assert_equal 20, result["Test"][Date.new(2024, 1, 3)]
    assert_equal 0, result["Test"][Date.new(2024, 1, 4)]
    assert_equal 0, result["Test"][Date.new(2024, 1, 5)]
  end

  test "uses data bounds when no explicit range provided for daily interval" do
    builder = TimeSeriesBuilder.new(interval: "daily")

    data = [
      MockRow.new(date: Date.new(2024, 1, 5), value: 10),
      MockRow.new(date: Date.new(2024, 1, 3), value: 20)
    ]

    result = builder.build(data, { "Test" => :value })

    # Should fill from first to last data point
    assert_equal 3, result["Test"].size
  end

  test "supports start_date only, uses last data point as end" do
    builder = TimeSeriesBuilder.new(
      interval: "daily",
      start_date: Date.new(2024, 1, 1)
    )

    data = [
      MockRow.new(date: Date.new(2024, 1, 3), value: 10),
      MockRow.new(date: Date.new(2024, 1, 5), value: 20)
    ]

    result = builder.build(data, { "Test" => :value })

    assert_equal 5, result["Test"].size
    assert_equal(Date.new(2024, 1, 1), result["Test"].keys.first)
    assert_equal(Date.new(2024, 1, 5), result["Test"].keys.last)
  end

  test "supports end_date only, uses first data point as start" do
    builder = TimeSeriesBuilder.new(
      interval: "daily",
      end_date: Date.new(2024, 1, 5)
    )

    data = [
      MockRow.new(date: Date.new(2024, 1, 1), value: 10),
      MockRow.new(date: Date.new(2024, 1, 3), value: 20)
    ]

    result = builder.build(data, { "Test" => :value })

    assert_equal 5, result["Test"].size
    assert_equal(Date.new(2024, 1, 1), result["Test"].keys.first)
    assert_equal(Date.new(2024, 1, 5), result["Test"].keys.last)
  end

  test "supports multiple series configurations" do
    builder = TimeSeriesBuilder.new(
      interval: "daily",
      start_date: Date.new(2024, 1, 1),
      end_date: Date.new(2024, 1, 3)
    )

    data = [
      MockRow.new(date: Date.new(2024, 1, 1), value_a: 10, value_b: 100),
      MockRow.new(date: Date.new(2024, 1, 3), value_a: 30, value_b: 300)
    ]

    result = builder.build(data, { "Series A" => :value_a, "Series B" => :value_b })

    assert_equal 3, result["Series A"].size
    assert_equal 3, result["Series B"].size
    assert_equal 10, result["Series A"][Date.new(2024, 1, 1)]
    assert_equal 100, result["Series B"][Date.new(2024, 1, 1)]
    assert_equal 0, result["Series A"][Date.new(2024, 1, 2)]
    assert_equal 0, result["Series B"][Date.new(2024, 1, 2)]
  end

  test "supports lambda configs for computed values" do
    builder = TimeSeriesBuilder.new(
      interval: "daily",
      start_date: Date.new(2024, 1, 1),
      end_date: Date.new(2024, 1, 2)
    )

    data = [
      MockRow.new(date: Date.new(2024, 1, 1), total: 100, count: 10)
    ]

    result = builder.build(data, {
      "Average" => ->(row) { count = row.count; count.positive? ? (row.total / count).round(2) : 0 }
    })

    assert_equal 10.0, result["Average"][Date.new(2024, 1, 1)]
    assert_equal 0, result["Average"][Date.new(2024, 1, 2)]
  end

  test "handles hourly interval with explicit range" do
    builder = TimeSeriesBuilder.new(
      interval: "hourly",
      start_date: Time.new(2024, 1, 1, 0, 0, 0),
      end_date: Time.new(2024, 1, 1, 3, 0, 0)
    )

    data = [
      MockRow.new(time_bucket: Time.new(2024, 1, 1, 0, 0, 0), value: 10),
      MockRow.new(time_bucket: Time.new(2024, 1, 1, 2, 0, 0), value: 20)
    ]

    result = builder.build(data, { "Test" => :value })

    assert_equal 4, result["Test"].size
    assert_equal 10, result["Test"][Time.new(2024, 1, 1, 0, 0, 0)]
    assert_equal 0, result["Test"][Time.new(2024, 1, 1, 1, 0, 0)]
    assert_equal 20, result["Test"][Time.new(2024, 1, 1, 2, 0, 0)]
    assert_equal 0, result["Test"][Time.new(2024, 1, 1, 3, 0, 0)]
  end

  test "handles hourly interval normalization with date input" do
    builder = TimeSeriesBuilder.new(
      interval: "hourly",
      start_date: Date.new(2024, 1, 1),
      end_date: Date.new(2024, 1, 1)
    )

    data = []
    result = builder.build(data, { "Test" => :value })

    # Should have 24 hours in a day
    assert_equal 24, result["Test"].size
    assert result["Test"].keys.all? { |k| k.is_a?(Time) }
  end

  test "handles weekly interval with explicit range" do
    builder = TimeSeriesBuilder.new(
      interval: "weekly",
      start_date: Date.new(2024, 1, 1),
      end_date: Date.new(2024, 1, 31)
    )

    data = [
      MockRow.new(week_start: Date.new(2024, 1, 1), value: 100),
      MockRow.new(week_start: Date.new(2024, 1, 22), value: 200)
    ]

    result = builder.build(data, { "Test" => :value })

    # Should have 5 weeks (Jan 1, 8, 15, 22, 29)
    assert_equal 5, result["Test"].size
    assert_equal 100, result["Test"][Date.new(2024, 1, 1)]
    assert_equal 0, result["Test"][Date.new(2024, 1, 8)]
    assert_equal 0, result["Test"][Date.new(2024, 1, 15)]
    assert_equal 200, result["Test"][Date.new(2024, 1, 22)]
  end

  test "ensures weekly intervals start on Monday" do
    builder = TimeSeriesBuilder.new(
      interval: "weekly",
      start_date: Date.new(2024, 1, 5), # Friday
      end_date: Date.new(2024, 1, 12)   # Friday
    )

    data = []
    result = builder.build(data, { "Test" => :value })

    # Should start from Monday Jan 1, not Friday Jan 5
    assert_equal Date.new(2024, 1, 1), result["Test"].keys.first
  end

  test "empty data with explicit range returns zero-filled series" do
    builder = TimeSeriesBuilder.new(
      interval: "daily",
      start_date: Date.new(2024, 1, 1),
      end_date: Date.new(2024, 1, 3)
    )

    result = builder.build([], { "Test" => :value })

    assert_equal 3, result["Test"].size
    assert result["Test"].values.all? { |v| v.zero? }
  end

  test "handles single data point without explicit range" do
    builder = TimeSeriesBuilder.new(interval: "daily")

    data = [MockRow.new(date: Date.new(2024, 1, 15), value: 42)]

    result = builder.build(data, { "Test" => :value })

    assert_equal 1, result["Test"].size
    assert_equal 42, result["Test"][Date.new(2024, 1, 15)]
  end

  test "handles lambda returning zero for missing values" do
    builder = TimeSeriesBuilder.new(
      interval: "daily",
      start_date: Date.new(2024, 1, 1),
      end_date: Date.new(2024, 1, 3)
    )

    data = [
      MockRow.new(date: Date.new(2024, 1, 1), count: 10),
      MockRow.new(date: Date.new(2024, 1, 3), count: 0)
    ]

    result = builder.build(data, {
      "Safe Divide" => ->(row) { row.count.positive? ? 100 / row.count : 0 }
    })

    assert_equal 10, result["Safe Divide"][Date.new(2024, 1, 1)]
    assert_equal 0, result["Safe Divide"][Date.new(2024, 1, 2)]
    assert_equal 0, result["Safe Divide"][Date.new(2024, 1, 3)]
  end
end

class MockRow
  def initialize(**attributes)
    @attributes = attributes
  end

  def method_missing(name, *args)
    if @attributes.key?(name)
      @attributes[name]
    else
      super
    end
  end

  def respond_to_missing?(name, _include_private = false)
    @attributes.key?(name) || super
  end
end
