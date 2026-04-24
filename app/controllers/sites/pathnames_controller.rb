# frozen_string_literal: true

module Sites
  class PathnamesController < ApplicationController
    include FilterStats

    before_action :authenticate_user!
    before_action :set_site

    def index
      @display_hostname = @site.display_hostname
      @stats = build_pathname_query
        .paginate(page: params[:page], per_page: PER_PAGE)
    end

    private

    def build_pathname_query
      base_query = stats_model.for_site(@site.id)

      # If dimension filter is applied, use dimension scope; otherwise use global scope
      if current_dimension_type.present? && current_dimension_value.present?
        base_query = base_query.for_dimension(current_dimension_type, current_dimension_value)
      else
        base_query = base_query.global
      end

      # Filter by pathname and optional hostname
      if current_pathname.present?
        base_query = base_query.where(pathname: current_pathname)
        base_query = base_query.where(hostname: current_hostname) if current_hostname.present?
      end

      base_query = apply_date_range_filter(base_query)

      # Build grouped aggregate query
      group_columns = @display_hostname ? [:hostname, :pathname] : [:pathname]

      base_query
        .group(*group_columns)
        .select(build_select_clause(group_columns))
        .order("SUM(pageviews) DESC")
    end

    def build_select_clause(group_columns)
      columns = group_columns.map(&:to_s)
      aggregates = %w[pageviews unique_pageviews visits sessions bounced_count total_duration duration_count]
        .map { |col| "SUM(#{col}) as #{col}" }
      (columns + aggregates).join(", ")
    end
  end
end
