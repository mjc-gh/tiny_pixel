# frozen_string_literal: true

module IntervalStats
  extend ActiveSupport::Concern

  VALID_INTERVALS = %w[hourly daily weekly].freeze
  DEFAULT_INTERVAL = "daily"
  VALID_VIEW_MODES = %w[graph table].freeze
  DEFAULT_VIEW_MODE = "graph"
  PER_PAGE = 20

  included do
    helper_method :current_interval, :stats_time_column, :current_view_mode
  end

  def current_interval
    @current_interval ||= begin
      interval = params[:interval]
      VALID_INTERVALS.include?(interval) ? interval : DEFAULT_INTERVAL
    end
  end

  def current_view_mode
    @current_view_mode ||= begin
      view_mode = params[:view_mode]
      VALID_VIEW_MODES.include?(view_mode) ? view_mode : DEFAULT_VIEW_MODE
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
end
