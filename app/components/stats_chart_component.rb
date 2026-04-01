# frozen_string_literal: true

class StatsChartComponent < ViewComponent::Base
  def initialize(data:, time_column:, chart_id:)
    @data = data
    @time_column = time_column
    @chart_id = chart_id
  end

  def chart_data
    @data.map do |series_name, values|
      { name: series_name, data: values }
    end
  end

  def chart_options
    {
      id: @chart_id,
      library: {
        scales: {
          x: {
            type: "time",
            time: {
              unit: time_unit
            }
          }
        }
      }
    }
  end

  def has_data?
    @data.values.any? { |series| series.any? }
  end

  private

  def time_unit
    case @time_column
    when :time_bucket
      "hour"
    when :week_start
      "week"
    else
      "day"
    end
  end
end
