# frozen_string_literal: true

module Sites
  class PageViewsController < ApplicationController
    include IntervalStats

    before_action :authenticate_user!
    before_action :set_site

    def index
      @stats = stats_model
        .for_site(@site.id)
        .global
        .public_send(stats_ordered_scope)
        .paginate(page: params[:page], per_page: PER_PAGE)

      scope = stats_model.for_site(@site.id).global
      scope = scope.for_pathname(current_pathname) if current_pathname.present?
      scope = scope.where(hostname: current_hostname) if current_hostname.present?
      scope = apply_date_range_filter(scope)

      @chart_data = {
        "Page Views" => scope.group(stats_time_column).sum(:pageviews),
        "Unique Page Views" => scope.group(stats_time_column).sum(:unique_pageviews)
      }
    end
  end
end
