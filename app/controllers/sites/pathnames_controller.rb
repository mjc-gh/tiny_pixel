# frozen_string_literal: true

module Sites
  class PathnamesController < ApplicationController
    include FilterStats

    before_action :authenticate_user!
    before_action :set_site

    def index
      @display_hostname = @site.display_hostname
      @pathname_stats = build_pathname_stats

      stats_array = @pathname_stats
        .map { |key, metrics| build_stat_object(key, metrics, @display_hostname) }
        .sort_by { |stat| -stat.pageviews }

      @stats = WillPaginate::Collection.create(
        params[:page] || 1,
        PER_PAGE,
        stats_array.length
      ) do |pager|
        pager.replace(stats_array[pager.offset, pager.per_page])
      end
    end

    private

    def build_pathname_stats
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

      stats = {}

      if @display_hostname
        # Group by hostname and pathname
        hostname_pathnames = base_query.distinct.pluck(:hostname, :pathname)
        hostname_pathnames.each do |hostname, pathname|
          query = base_query.where(hostname: hostname, pathname: pathname)
          key = [hostname, pathname]
          stats[key] = [
            query.sum(:pageviews),
            query.sum(:unique_pageviews),
            query.sum(:visits),
            query.sum(:sessions),
            query.sum(:bounced_count),
            query.sum(:total_duration),
            query.sum(:duration_count)
          ]
        end
      else
        # Group by pathname only
        pathnames = base_query.distinct.pluck(:pathname)
        pathnames.each do |pathname|
          query = base_query.where(pathname: pathname)
          stats[pathname] = [
            query.sum(:pageviews),
            query.sum(:unique_pageviews),
            query.sum(:visits),
            query.sum(:sessions),
            query.sum(:bounced_count),
            query.sum(:total_duration),
            query.sum(:duration_count)
          ]
        end
      end

      stats
    end

    def build_stat_object(key, metrics, display_hostname)
      if display_hostname
        hostname, pathname = key
        PageviewStat.new(
          hostname: hostname,
          pathname: pathname,
          pageviews: metrics[0],
          unique_pageviews: metrics[1],
          visits: metrics[2],
          sessions: metrics[3],
          bounced_count: metrics[4],
          total_duration: metrics[5],
          duration_count: metrics[6]
        )
      else
        PageviewStat.new(
          pathname: key,
          pageviews: metrics[0],
          unique_pageviews: metrics[1],
          visits: metrics[2],
          sessions: metrics[3],
          bounced_count: metrics[4],
          total_duration: metrics[5],
          duration_count: metrics[6]
        )
      end
    end
  end
end
