# frozen_string_literal: true

module Sites
  class PerformanceController < ApplicationController
    include IntervalStats

    before_action :authenticate_user!
    before_action :set_site

    def index
      @stats = stats_model
        .for_site(@site.id)
        .public_send(stats_ordered_scope)
        .paginate(page: params[:page], per_page: PER_PAGE)

      @chart_data = build_performance_chart_data
    end

    def build_performance_chart_data
      aggregated = stats_model
        .for_site(@site.id)
        .group(stats_time_column)
        .select(
          stats_time_column,
          "SUM(total_duration) as total_duration",
          "SUM(duration_count) as duration_count",
          "SUM(bounced_count) as bounced_count",
          "SUM(pageviews) as pageviews"
        )

      avg_duration_data = {}
      bounce_rate_data = {}

      aggregated.each do |row|
        time_key = row.public_send(stats_time_column)
        avg_duration_data[time_key] = row.duration_count.positive? ? (row.total_duration / row.duration_count).round(2) : 0
        bounce_rate_data[time_key] = row.pageviews.positive? ? (row.bounced_count.to_f / row.pageviews * 100).round(2) : 0
      end

      {
        "Avg Duration (s)" => avg_duration_data,
        "Bounce Rate (%)" => bounce_rate_data
      }
    end
  end
end
