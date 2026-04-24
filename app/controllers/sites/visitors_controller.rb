# frozen_string_literal: true

module Sites
  class VisitorsController < ApplicationController
    include FilterStats

    before_action :authenticate_user!
    before_action :set_site

    def index
      base_scope = stats_model.for_site(@site.id)

      # If dimension filter is applied, use dimension scope; otherwise use global scope
      if current_dimension_type.present? && current_dimension_value.present?
        base_scope = base_scope.for_dimension(current_dimension_type, current_dimension_value)
      else
        base_scope = base_scope.global
      end

      @stats = base_scope
        .public_send(stats_ordered_scope)
        .paginate(page: params[:page], per_page: PER_PAGE)

      scope = base_scope
      scope = scope.for_pathname(current_pathname) if current_pathname.present?
      scope = scope.where(hostname: current_hostname) if current_hostname.present?
      scope = apply_date_range_filter(scope)

      aggregated = scope
        .group(stats_time_column)
        .select(
          stats_time_column,
          "SUM(visits) as visits",
          "SUM(sessions) as sessions"
        )

      visits_data = {}
      sessions_data = {}

      aggregated.each do |row|
        time_key = row.public_send(stats_time_column)
        visits_data[time_key] = row.visits
        sessions_data[time_key] = row.sessions
      end

      @chart_data = {
        "Visits" => visits_data,
        "Sessions" => sessions_data
      }
    end
  end
end
