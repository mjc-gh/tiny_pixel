# frozen_string_literal: true

module Sites
  class AvgDurationController < ApplicationController
    include FilterStats

    before_action :authenticate_user!
    before_action :set_site

    def index
      @chart_data = build_time_series_chart(
        select_columns: [stats_time_column, "SUM(total_duration) as total_duration", "SUM(duration_count) as duration_count"],
        series: {
          "Avg Duration (s)" => lambda { |row|
            row.duration_count.positive? ? (row.total_duration / row.duration_count).round(2) : 0
          }
        }
      )
    end
  end
end
