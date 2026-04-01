# frozen_string_literal: true

class StatsTableComponent < ViewComponent::Base
  def initialize(stats:, columns:, time_column:)
    @stats = stats
    @columns = columns
    @time_column = time_column
  end

  def format_time(stat)
    time_value = stat.public_send(@time_column)
    case @time_column
    when :time_bucket
      time_value.strftime("%Y-%m-%d %H:%M")
    when :week_start
      "Week of #{time_value.strftime('%b %d, %Y')}"
    else
      time_value.strftime("%b %d, %Y")
    end
  end

  def format_value(stat, method)
    value = stat.public_send(method)
    return "N/A" if value.nil?

    case method
    when :bounce_rate
      "#{value}%"
    when :avg_duration
      "#{value.round(2)}s"
    else
      value.is_a?(Numeric) ? number_with_delimiter(value) : value
    end
  end
end
