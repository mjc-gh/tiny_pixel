# frozen_string_literal: true

module FilterStats
  extend ActiveSupport::Concern

  VALID_INTERVALS = %w[hourly daily weekly].freeze
  VALID_DIMENSION_TYPES = %w[country browser device_type referrer_hostname utm_source utm_medium utm_campaign].freeze

  DEFAULT_INTERVAL = "daily"
  PER_PAGE = 20

  included do
    helper_method :current_interval, :current_pathname, :current_hostname, :stats_time_column,
                  :current_start_date, :current_end_date, :current_dimension_type, :current_dimension_value,
                  :default_start_date
  end

  def build_time_series_chart(select_columns:, series:)
    scope = filtered_stats_scope
    aggregated = scope.group(stats_time_column).select(*select_columns)

    # Convert series config to lambdas if needed
    series_configs = series.transform_values do |column_or_lambda|
      column_or_lambda.is_a?(Symbol) ? column_or_lambda : column_or_lambda
    end

    builder = TimeSeriesBuilder.new(
      interval: current_interval,
      start_date: current_start_date,
      end_date: current_end_date
    )

    builder.build(aggregated, series_configs)
  end

  def filtered_stats_scope
    scope = stats_model.for_site(@site.id)

    # Apply dimension filter
    if current_dimension_type.present? && current_dimension_value.present?
      scope = scope.for_dimension(current_dimension_type, current_dimension_value)
    else
      scope = scope.global
    end

    # Apply pathname filter
    scope = scope.for_pathname(current_pathname) if current_pathname.present?

    # Apply hostname filter
    scope = scope.where(hostname: current_hostname) if current_hostname.present?

    # Apply date range filter
    apply_date_range_filter(scope)
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

  def current_dimension_type
    @current_dimension_type ||= params[:dimension_type] if valid_filter_dimension_type?
  end

  def current_dimension_value
    @current_dimension_value ||= params[:dimension_value]
  end

  def current_start_date
    @current_start_date ||= parse_date_param(:start_date) || (parse_date_param(:end_date).nil? ? default_start_date : nil)
  end

  def current_end_date
    @current_end_date ||= parse_date_param(:end_date)
  end

  def default_start_date
    case current_interval
    when "hourly"
      1.day.ago.beginning_of_day.to_date
    when "weekly"
      6.weeks.ago.beginning_of_week.to_date
    else # daily
      7.days.ago.to_date
    end
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
    return scope unless current_start_date || current_end_date
    scope.for_date_range(current_start_date, current_end_date)
  end

  private

  def valid_filter_dimension_type?
    VALID_DIMENSION_TYPES.include?(params[:dimension_type])
  end

  def parse_date_param(param_name)
    return nil if params[param_name].blank?
    Date.parse(params[param_name])
  rescue Date::Error
    nil
  end
end
