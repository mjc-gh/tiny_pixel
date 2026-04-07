# frozen_string_literal: true

module Sites
  class PathnamesController < ApplicationController
    include IntervalStats

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

    class PageviewStat
      attr_reader :hostname, :pathname, :pageviews, :unique_pageviews, :visits, :sessions,
                  :bounced_count, :total_duration, :duration_count

      def initialize(pathname:, pageviews:, unique_pageviews:, visits:, sessions:,
                     bounced_count:, total_duration:, duration_count:, hostname: nil)
        @hostname = hostname
        @pathname = pathname
        @pageviews = pageviews
        @unique_pageviews = unique_pageviews
        @visits = visits
        @sessions = sessions
        @bounced_count = bounced_count
        @total_duration = total_duration
        @duration_count = duration_count
      end

      def bounce_rate
        return nil if pageviews.zero?

        (bounced_count.to_f / pageviews * 100).round(2)
      end

      def avg_duration
        return nil if duration_count.zero?

        total_duration / duration_count
      end
    end
  end
end
