# frozen_string_literal: true

class TimeSeriesBuilder
  def initialize(interval:, start_date: nil, end_date: nil)
    @interval = interval
    @start_date = start_date
    @end_date = end_date
  end

  def build(aggregated_data, series_configs)
    time_points = generate_time_points(aggregated_data)
    return {} if time_points.empty?

    build_zero_filled_series(time_points, aggregated_data, series_configs)
  end

  private

  attr_reader :interval, :start_date, :end_date

  def has_explicit_range?
    start_date.present? || end_date.present?
  end

  def generate_time_points(aggregated_data)
    if aggregated_data.empty?
      return [] unless has_explicit_range?
      return generate_time_range(@start_date, @end_date)
    end

    # Extract first and last time points from data
    time_column = time_column_name
    time_values = aggregated_data.map { |row| row.public_send(time_column) }
    first_point = time_values.min
    last_point = time_values.max

    range_start = @start_date || first_point
    range_end = @end_date || last_point

    generate_time_range(range_start, range_end)
  end

  def generate_time_range(start_point, end_point)
    return [] if start_point.nil? || end_point.nil?

    case interval
    when "hourly"
      generate_hourly_range(start_point, end_point)
    when "weekly"
      generate_weekly_range(start_point, end_point)
    else
      generate_daily_range(start_point, end_point)
    end
  end

  def generate_hourly_range(start_time, end_time)
    # Convert dates to times if needed
    is_start_date = start_time.is_a?(Date) && !start_time.is_a?(Time)
    is_end_date = end_time.is_a?(Date) && !end_time.is_a?(Time)

    start_time = start_time.to_time if is_start_date
    end_time = end_time.to_time if is_end_date

    # If end_date was a Date input, extend to end of day
    if is_end_date && end_time == end_time.beginning_of_day
      end_time = end_time.end_of_day
    end

    # Normalize to hour boundaries
    start_time = start_time.beginning_of_hour
    end_time = end_time.end_of_hour

    result = []
    current = start_time
    while current <= end_time
      result << current
      current += 1.hour
    end
    result
  end

  def generate_daily_range(start_date, end_date)
    start_date = start_date.to_date if start_date.is_a?(Time)
    end_date = end_date.to_date if end_date.is_a?(Time)

    (start_date..end_date).to_a
  end

  def generate_weekly_range(start_date, end_date)
    start_date = start_date.to_date if start_date.is_a?(Time)
    end_date = end_date.to_date if end_date.is_a?(Time)

    # Ensure start_date is a Monday (week start)
    start_date = start_date.beginning_of_week(:monday)
    end_date = end_date.beginning_of_week(:monday)

    result = []
    current = start_date
    while current <= end_date
      result << current
      current += 1.week
    end
    result
  end

  def build_zero_filled_series(time_points, aggregated_data, series_configs)
    result = {}

    series_configs.each do |series_name, column_or_lambda|
      result[series_name] = build_zero_filled_column(time_points, aggregated_data, column_or_lambda)
    end

    result
  end

  def build_zero_filled_column(time_points, aggregated_data, column_or_lambda)
    time_column = time_column_name
    data_map = {}

    aggregated_data.each do |row|
      key = row.public_send(time_column)
      value = if column_or_lambda.is_a?(Proc)
        column_or_lambda.call(row)
      else
        row.public_send(column_or_lambda)
      end
      data_map[key] = value
    end

    # Build zero-filled result for all time points
    result = {}
    time_points.each do |time_point|
      result[time_point] = data_map[time_point] || 0
    end

    result
  end

  def time_column_name
    case interval
    when "hourly"
      :time_bucket
    when "weekly"
      :week_start
    else
      :date
    end
  end
end
