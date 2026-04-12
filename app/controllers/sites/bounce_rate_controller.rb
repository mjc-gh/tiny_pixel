# frozen_string_literal: true

module Sites
  class BounceRateController < ApplicationController
    include FilterStats

    before_action :authenticate_user!
    before_action :set_site

    def index
      build_bounce_rate_chart_data
    end

    private

    def build_bounce_rate_chart_data
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
          "SUM(bounced_count) as bounced_count",
          "SUM(pageviews) as pageviews"
        )

      bounce_rate_data = {}

      aggregated.each do |row|
        time_key = row.public_send(stats_time_column)
        bounce_rate_data[time_key] = row.pageviews.positive? ? (row.bounced_count.to_f / row.pageviews * 100).round(2) : 0
      end

      @chart_data = { "Bounce Rate (%)" => bounce_rate_data }
    end
  end
end
