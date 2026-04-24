# frozen_string_literal: true

module Sites
  class DimensionsController < ApplicationController
    include FilterStats

    DIMENSION_PER_PAGE = 5

    before_action :authenticate_user!
    before_action :set_site

    def index
      @type = params[:type]
      @dimension_type = @type

      unless VALID_DIMENSION_TYPES.include?(@type)
        render plain: "Invalid dimension type", status: :bad_request
        return
      end

      scope = stats_model
        .for_site(@site.id)
        .for_dimension_type(@type)

      scope = apply_date_range_filter(scope)
      scope = scope.where(pathname: current_pathname) if current_pathname.present?
      scope = scope.where(hostname: current_hostname) if current_hostname.present?
      scope = scope.for_dimension(current_dimension_type, current_dimension_value) if current_dimension_type.present? && current_dimension_value.present?

      # Group by dimension_value and sum metrics
      @stats = scope
        .group(:dimension_value)
        .select("dimension_value, SUM(pageviews) as pageviews, SUM(sessions) as sessions")
        .order("SUM(pageviews) DESC")
        .paginate(page: params[:page], per_page: DIMENSION_PER_PAGE)

      @frame_id = "#{@type}_stats"
    end

    private

    def set_site
      @site = current_user.sites.find(params[:site_id])
    rescue ActiveRecord::RecordNotFound
      render plain: "Site not found", status: :not_found
    end
  end
end
