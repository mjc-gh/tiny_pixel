# frozen_string_literal: true

module Sites
  class PageViewsController < ApplicationController
    include IntervalStats

    before_action :authenticate_user!
    before_action :set_site

    def index
      @stats = stats_model
        .for_site(@site.id)
        .public_send(stats_ordered_scope)
        .paginate(page: params[:page], per_page: PER_PAGE)

      @chart_data = {
        "Page Views" => stats_model.for_site(@site.id).group(stats_time_column).sum(:pageviews),
        "Unique Page Views" => stats_model.for_site(@site.id).group(stats_time_column).sum(:unique_pageviews)
      }
    end
  end
end
