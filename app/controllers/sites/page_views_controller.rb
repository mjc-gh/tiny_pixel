# frozen_string_literal: true

module Sites
  class PageViewsController < ApplicationController
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

      @chart_data = build_time_series_chart(
        select_columns: [stats_time_column, "SUM(pageviews) as pageviews", "SUM(unique_pageviews) as unique_pageviews"],
        series: { "Page Views" => :pageviews, "Unique Page Views" => :unique_pageviews }
      )
    end
  end
end
