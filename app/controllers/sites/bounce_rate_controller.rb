# frozen_string_literal: true

module Sites
  class BounceRateController < ApplicationController
    include FilterStats

    before_action :authenticate_user!
    before_action :set_site

    def index
      @chart_data = build_time_series_chart(
        select_columns: [stats_time_column, "SUM(bounced_count) as bounced_count", "SUM(pageviews) as pageviews"],
        series: {
          "Bounce Rate (%)" => lambda { |row|
            row.pageviews.positive? ? (row.bounced_count.to_f / row.pageviews * 100).round(2) : 0
          }
        }
      )
    end
  end
end
