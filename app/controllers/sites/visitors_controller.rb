# frozen_string_literal: true

module Sites
  class VisitorsController < ApplicationController
    include IntervalStats

    before_action :authenticate_user!
    before_action :set_site

    def index
      @stats = stats_model
        .for_site(@site.id)
        .public_send(stats_ordered_scope)
        .paginate(page: params[:page], per_page: PER_PAGE)

      @chart_data = {
        "Visits" => stats_model.for_site(@site.id).group(stats_time_column).sum(:visits),
        "Sessions" => stats_model.for_site(@site.id).group(stats_time_column).sum(:sessions)
      }
    end

    private

    def set_site
      @site = current_user.sites.find(params[:site_id])
    end
  end
end
