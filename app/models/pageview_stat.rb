# frozen_string_literal: true

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
