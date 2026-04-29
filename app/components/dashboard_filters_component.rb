# frozen_string_literal: true

class DashboardFiltersComponent < ViewComponent::Base
  INTERVALS = [
    { value: "hourly", label: "Hourly" },
    { value: "daily", label: "Daily" },
    { value: "weekly", label: "Weekly" }
  ].freeze

  def initialize(current_interval:, start_date:, end_date:, site:, pathname: nil, hostname: nil, dimension_type: nil, dimension_value: nil, visible: false)
    @current_interval = current_interval
    @start_date = start_date
    @end_date = end_date
    @site = site
    @pathname = pathname
    @hostname = hostname
    @dimension_type = dimension_type
    @dimension_value = dimension_value
    @visible = visible
  end

  def intervals
    INTERVALS
  end

  def selected?(value)
    @current_interval == value
  end

  def start_date_value
    @start_date&.iso8601
  end

  def end_date_value
    @end_date&.iso8601
  end

  def display_summary
    date_range = if @start_date && @end_date
      "#{@start_date.strftime('%b %-d')} - #{@end_date.strftime('%b %-d')}"
    elsif @start_date
      "#{@start_date.strftime('%b %-d')} to now"
    elsif @end_date
      "oldest to #{@end_date.strftime('%b %-d')}"
    else
      "Date range"
    end

    "#{@current_interval.capitalize} · #{date_range}"
  end
end
