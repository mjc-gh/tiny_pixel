# frozen_string_literal: true

module Sites
  class PathnamesController < ApplicationController
    include IntervalStats

    before_action :authenticate_user!
    before_action :set_site

    def index
      @pathname_stats = build_pathname_stats

      stats_array = @pathname_stats
        .map { |pathname, metrics| build_stat_object(pathname, metrics) }
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

      pathnames = base_query.distinct.pluck(:pathname)
      stats = {}

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

      stats
    end

    def build_stat_object(pathname, metrics)
      PageviewStat.new(
        pathname: pathname,
        pageviews: metrics[0],
        unique_pageviews: metrics[1],
        visits: metrics[2],
        sessions: metrics[3],
        bounced_count: metrics[4],
        total_duration: metrics[5],
        duration_count: metrics[6]
      )
    end

    class PageviewStat
      attr_reader :pathname, :pageviews, :unique_pageviews, :visits, :sessions,
                  :bounced_count, :total_duration, :duration_count

      def initialize(pathname:, pageviews:, unique_pageviews:, visits:, sessions:,
                     bounced_count:, total_duration:, duration_count:)
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
