# frozen_string_literal: true

module Sites
  class PerformanceController < ApplicationController
    include IntervalStats

    before_action :authenticate_user!
    before_action :set_site

    def index
      @stats = stats_model
        .for_site(@site.id)
        .public_send(stats_ordered_scope)
        .paginate(page: params[:page], per_page: PER_PAGE)
    end

    private

    def set_site
      @site = current_user.sites.find(params[:site_id])
    end
  end
end
