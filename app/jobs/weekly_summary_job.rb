# frozen_string_literal: true

class WeeklySummaryJob < ApplicationJob
  queue_as :default

  def perform
    return unless TinyPixel.email_delivery_supported?

    # Find all users with at least one site membership
    User.joins(:memberships).distinct.find_each do |user|
      sites = user.sites
      next if sites.empty?

      # Compute stats for each site
      sites_data = sites.map { |site| compute_site_stats(site) }

      # Send email
      SitesMailer.weekly_summary(user, sites_data).deliver_later
    end
  end

  private

  def compute_site_stats(site)
    start_date = 7.days.ago.to_date
    end_date = 1.day.ago.to_date

    # Query daily page stats for global dimension
    stats = DailyPageStat.for_site(site.id).global.for_date_range(start_date, end_date)

    # Return empty data structure if no stats
    return build_empty_site_data(site) if stats.empty?

    # Compute aggregated values
    total_pageviews = stats.sum(:pageviews)
    total_sessions = stats.sum(:sessions)
    total_duration = stats.sum(:total_duration)
    total_duration_count = stats.sum(:duration_count)

    # Daily averages (divide by 7 days)
    avg_daily_pageviews = total_pageviews / 7.0
    avg_daily_sessions = total_sessions / 7.0
    avg_daily_duration = total_duration_count > 0 ? total_duration / total_duration_count : nil

    # Find top page by sessions
    top_by_sessions = stats
                      .group(:pathname)
                      .select(:pathname)
                      .select(Arel.sql("SUM(sessions) as sessions_sum"))
                      .order(Arel.sql("sessions_sum DESC"))
                      .limit(1)
                      .first

    top_page_by_sessions = if top_by_sessions
      {
        pathname: top_by_sessions.pathname,
        sessions: top_by_sessions.sessions_sum.to_i
      }
    end

    # Find top page by average duration
    top_by_duration_data = stats
                           .where("duration_count > 0")
                           .group(:pathname)
                           .select(:pathname, Arel.sql("SUM(total_duration) / CAST(SUM(duration_count) as DECIMAL) as avg_duration_calc"))
                           .order(Arel.sql("avg_duration_calc DESC"))
                           .limit(1)
                           .first

    top_page_by_duration = if top_by_duration_data
      {
        pathname: top_by_duration_data.pathname,
        avg_duration: top_by_duration_data.avg_duration_calc.to_f
      }
    end

    {
      site: site,
      avg_daily_pageviews: avg_daily_pageviews,
      avg_daily_sessions: avg_daily_sessions,
      avg_daily_duration: avg_daily_duration,
      top_page_by_sessions: top_page_by_sessions,
      top_page_by_duration: top_page_by_duration
    }
  end

  def build_empty_site_data(site)
    {
      site: site,
      avg_daily_pageviews: 0.0,
      avg_daily_sessions: 0.0,
      avg_daily_duration: nil,
      top_page_by_sessions: nil,
      top_page_by_duration: nil
    }
  end
end
