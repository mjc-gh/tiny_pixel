# frozen_string_literal: true

module IntervalStats
  extend ActiveSupport::Concern

  VALID_INTERVALS = %w[hourly daily weekly].freeze
  DEFAULT_INTERVAL = "daily"
  PER_PAGE = 20

  included do
    helper_method :current_interval, :current_pathname, :current_hostname, :stats_time_column,
                  :current_start_date, :current_end_date
  end

  def current_interval
    @current_interval ||= begin
      interval = params[:interval]
      VALID_INTERVALS.include?(interval) ? interval : DEFAULT_INTERVAL
    end
  end

  def current_pathname
    @current_pathname ||= params[:pathname]
  end

  def current_hostname
    @current_hostname ||= params[:hostname]
  end

  def current_start_date
    @current_start_date ||= parse_date_param(:start_date)
  end

  def current_end_date
    @current_end_date ||= parse_date_param(:end_date)
  end

  def stats_model
    case current_interval
    when "hourly"
      HourlyPageStat
    when "weekly"
      WeeklyPageStat
    else
      DailyPageStat
    end
  end

  def stats_ordered_scope
    case current_interval
    when "hourly"
      :ordered_by_time
    when "weekly"
      :ordered_by_week
    else
      :ordered_by_date
    end
  end

  def stats_time_column
    case current_interval
    when "hourly"
      :time_bucket
    when "weekly"
      :week_start
    else
      :date
    end
  end

  def apply_date_range_filter(scope)
    return scope unless current_start_date && current_end_date
    scope.for_date_range(current_start_date, current_end_date)
  end

  private

  def parse_date_param(param_name)
    return nil if params[param_name].blank?
    Date.parse(params[param_name])
  rescue Date::Error
    nil
  end
end
