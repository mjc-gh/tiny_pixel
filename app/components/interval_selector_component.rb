# frozen_string_literal: true

class IntervalSelectorComponent < ViewComponent::Base
  INTERVALS = [
    { value: "hourly", label: "Hourly" },
    { value: "daily", label: "Daily" },
    { value: "weekly", label: "Weekly" }
  ].freeze

  def initialize(current_interval:, site:, pathname: nil, hostname: nil, start_date: nil, end_date: nil, dimension_type: nil, dimension_value: nil)
    @current_interval = current_interval
    @site = site
    @pathname = pathname
    @hostname = hostname
    @start_date = start_date
    @end_date = end_date
    @dimension_type = dimension_type
    @dimension_value = dimension_value
  end

  def intervals
    INTERVALS
  end

  def selected?(value)
    @current_interval == value
  end

  def interval_path(interval)
    path_params = { interval: interval }
    path_params[:pathname] = @pathname if @pathname.present?
    path_params[:hostname] = @hostname if @hostname.present?
    path_params[:start_date] = @start_date.iso8601 if @start_date.present?
    path_params[:end_date] = @end_date.iso8601 if @end_date.present?
    path_params[:dimension_type] = @dimension_type if @dimension_type.present?
    path_params[:dimension_value] = @dimension_value if @dimension_value.present?
    helpers.site_path(@site, path_params)
  end
end
