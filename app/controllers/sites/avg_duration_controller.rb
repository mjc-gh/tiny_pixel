# frozen_string_literal: true

module Sites
  class AvgDurationController < ApplicationController
    include IntervalStats

    before_action :authenticate_user!
    before_action :set_site

    def index
      build_avg_duration_chart_data
    end

    private

    def build_avg_duration_chart_data
      scope = stats_model.for_site(@site.id)

      # If dimension filter is applied, use dimension scope; otherwise use global scope
      if current_dimension_type.present? && current_dimension_value.present?
        scope = scope.for_dimension(current_dimension_type, current_dimension_value)
      else
        scope = scope.global
      end

      scope = scope.for_pathname(current_pathname) if current_pathname.present?
      scope = scope.where(hostname: current_hostname) if current_hostname.present?
      scope = apply_date_range_filter(scope)

      aggregated = scope
        .group(stats_time_column)
        .select(
          stats_time_column,
          "SUM(total_duration) as total_duration",
          "SUM(duration_count) as duration_count"
        )

      avg_duration_data = {}

      aggregated.each do |row|
        time_key = row.public_send(stats_time_column)
        avg_duration_data[time_key] = row.duration_count.positive? ? (row.total_duration / row.duration_count).round(2) : 0
      end

      @chart_data = { "Avg Duration (s)" => avg_duration_data }
    end
  end
end
