# frozen_string_literal: true

class SiteStatsService
  def initialize(site)
    @site = site
  end

  def compute
    granularity = determine_granularity
    stats = fetch_stats(granularity)

    return build_empty_site_data if stats.empty?

    compute_aggregated_stats(granularity, stats)
  end

  private

  attr_reader :site

  def determine_granularity
    age_days = site.age_in_days

    case age_days
    when 0..1
      :hourly
    when 2..14
      :daily
    else
      :weekly
    end
  end

  def fetch_stats(granularity)
    case granularity
    when :hourly
      fetch_hourly_stats
    when :daily
      fetch_daily_stats
    when :weekly
      fetch_weekly_stats
    end
  end

  def fetch_hourly_stats
    end_time = Time.current
    start_time = 24.hours.ago

    HourlyPageStat.for_site(site.id).global.for_date_range(start_time, end_time)
  end

  def fetch_daily_stats
    end_date = 1.day.ago.to_date
    start_date = 7.days.ago.to_date

    DailyPageStat.for_site(site.id).global.for_date_range(start_date, end_date)
  end

  def fetch_weekly_stats
    end_date = 1.day.ago.to_date
    start_date = 28.days.ago.to_date

    WeeklyPageStat.for_site(site.id).global.for_date_range(start_date, end_date)
  end

  def compute_aggregated_stats(granularity, stats)
    total_pageviews = stats.sum(:pageviews)
    total_sessions = stats.sum(:sessions)
    total_duration = stats.sum(:total_duration)
    total_duration_count = stats.sum(:duration_count)

    # Compute daily averages based on granularity
    period_days = calculate_period_days(granularity)
    avg_daily_pageviews = period_days > 0 ? total_pageviews / period_days.to_f : 0.0
    avg_daily_sessions = period_days > 0 ? total_sessions / period_days.to_f : 0.0
    avg_daily_duration = total_duration_count > 0 ? total_duration / total_duration_count : nil

    # Find top pages
    top_page_by_sessions = find_top_page_by_sessions(stats)
    top_page_by_duration = find_top_page_by_duration(stats)

    {
      site: site,
      granularity: granularity,
      period_days: period_days,
      avg_daily_pageviews: avg_daily_pageviews,
      avg_daily_sessions: avg_daily_sessions,
      avg_daily_duration: avg_daily_duration,
      top_page_by_sessions: top_page_by_sessions,
      top_page_by_duration: top_page_by_duration
    }
  end

  def calculate_period_days(granularity)
    case granularity
    when :hourly
      1
    when :daily
      7
    when :weekly
      28
    end
  end

  def find_top_page_by_sessions(stats)
    top_by_sessions = stats
                      .group(:pathname)
                      .select(:pathname)
                      .select(Arel.sql("SUM(sessions) as sessions_sum"))
                      .order(Arel.sql("sessions_sum DESC"))
                      .limit(1)
                      .first

    return unless top_by_sessions
    {
      pathname: top_by_sessions.pathname,
      sessions: top_by_sessions.sessions_sum.to_i
    }
  end

  def find_top_page_by_duration(stats)
    top_by_duration_data = stats
                           .where("duration_count > 0")
                           .group(:pathname)
                           .select(:pathname, Arel.sql("SUM(total_duration) / CAST(SUM(duration_count) as DECIMAL) as avg_duration_calc"))
                           .order(Arel.sql("avg_duration_calc DESC"))
                           .limit(1)
                           .first

    return unless top_by_duration_data
    {
      pathname: top_by_duration_data.pathname,
      avg_duration: top_by_duration_data.avg_duration_calc.to_f
    }
  end

  def build_empty_site_data
    {
      site: site,
      granularity: determine_granularity,
      period_days: 0,
      avg_daily_pageviews: 0.0,
      avg_daily_sessions: 0.0,
      avg_daily_duration: nil,
      top_page_by_sessions: nil,
      top_page_by_duration: nil
    }
  end
end
