# frozen_string_literal: true

module Sites
  class DimensionsController < ApplicationController
    include IntervalStats

    DIMENSION_PER_PAGE = 5
    VALID_DIMENSION_TYPES = %w[country browser device_type referrer_hostname].freeze

    before_action :authenticate_user!
    before_action :set_site

    def index
      dimension_type = params[:dimension_type]

      unless VALID_DIMENSION_TYPES.include?(dimension_type)
        render plain: "Invalid dimension type", status: :bad_request
        return
      end

      scope = stats_model
        .for_site(@site.id)
        .for_dimension_type(dimension_type)

      scope = apply_date_range_filter(scope)
      scope = scope.where(pathname: current_pathname) if current_pathname.present?
      scope = scope.where(hostname: current_hostname) if current_hostname.present?

      # Group by dimension_value and sum metrics
      grouped_stats = scope
        .group(:dimension_value)
        .select("dimension_value, SUM(pageviews) as pageviews, SUM(sessions) as sessions")
        .order("SUM(pageviews) DESC")

      # Convert to array of hashes for pagination
      stats_array = grouped_stats.map do |stat|
        {
          dimension_value: stat.dimension_value,
          pageviews: stat.pageviews.to_i,
          sessions: stat.sessions.to_i
        }
      end

      # Paginate the results
      @stats = WillPaginate::Collection.create(
        params[:page] || 1,
        DIMENSION_PER_PAGE,
        stats_array.length
      ) do |pager|
        pager.replace(stats_array[pager.offset, DIMENSION_PER_PAGE].to_a)
      end

      @dimension_type = dimension_type
      @frame_id = "#{dimension_type}_stats"
    end

    private

    def set_site
      @site = current_user.sites.find(params[:site_id])
    rescue ActiveRecord::RecordNotFound
      render plain: "Site not found", status: :not_found
    end
  end
end
