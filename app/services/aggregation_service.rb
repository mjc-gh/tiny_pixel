# frozen_string_literal: true

class AggregationService
  LOOKBACK_HOURS = 48

  class << self
    def aggregate_hourly_for_site(site, time_bucket)
      new(site).aggregate_hourly(time_bucket)
    end

    def aggregate_daily_for_site(site, date)
      new(site).aggregate_daily(date)
    end

    def aggregate_weekly_for_site(site, week_start)
      new(site).aggregate_weekly(week_start)
    end

    def aggregate_all_sites(lookback_hours: LOOKBACK_HOURS)
      Site.find_each do |site|
        new(site).aggregate_recent(lookback_hours: lookback_hours)
      end
    end
  end

  def initialize(site)
    @site = site
  end

  def aggregate_recent(lookback_hours: LOOKBACK_HOURS)
    end_time = round_to_hour(Time.current)
    start_time = end_time - lookback_hours.hours

    aggregate_hourly_range(start_time, end_time)
    aggregate_daily_range(start_time.to_date, end_time.to_date)
    aggregate_weekly_range(start_time.to_date, end_time.to_date)
  end

  def aggregate_hourly(time_bucket)
    time_bucket = round_to_hour(time_bucket)
    bucket_end = time_bucket + 1.hour

    raw_stats = fetch_raw_stats(time_bucket, bucket_end)
    return { created: 0, updated: 0 } if raw_stats.empty?

    upsert_hourly_stats(time_bucket, raw_stats)
  end

  def aggregate_daily(date)
    date = date.to_date
    start_time = date.beginning_of_day
    end_time = (date + 1.day).beginning_of_day

    raw_stats = fetch_raw_stats(start_time, end_time)
    return { created: 0, updated: 0 } if raw_stats.empty?

    upsert_daily_stats(date, raw_stats)
  end

  def aggregate_weekly(week_start)
    week_start = normalize_week_start(week_start)
    start_time = week_start.beginning_of_day
    end_time = (week_start + 7.days).beginning_of_day

    raw_stats = fetch_raw_stats(start_time, end_time)
    return { created: 0, updated: 0 } if raw_stats.empty?

    upsert_weekly_stats(week_start, raw_stats)
  end

  private

  def aggregate_hourly_range(start_time, end_time)
    current = round_to_hour(start_time)

    while current < end_time
      aggregate_hourly(current)
      current += 1.hour
    end
  end

  def aggregate_daily_range(start_date, end_date)
    (start_date..end_date).each do |date|
      aggregate_daily(date)
    end
  end

  def aggregate_weekly_range(start_date, end_date)
    week_starts = (start_date..end_date).map { |d| normalize_week_start(d) }.uniq

    week_starts.each do |week_start|
      aggregate_weekly(week_start)
    end
  end

  def fetch_raw_stats(start_time, end_time)
    PageView
      .joins("INNER JOIN visitors ON visitors.digest = page_views.visitor_digest")
      .where("visitors.property_id = ?", @site.id)
      .where(created_at: start_time...end_time)
      .group(:hostname, :pathname)
      .select(
        "page_views.hostname AS hostname",
        "page_views.pathname AS pathname",
        "COUNT(*) AS pageviews",
        "COUNT(DISTINCT CASE WHEN page_views.new_visit = 1 THEN page_views.visitor_digest END) AS visits",
        "COUNT(DISTINCT CASE WHEN page_views.new_session = 1 THEN page_views.visitor_digest END) AS sessions",
        "SUM(CASE WHEN page_views.is_unique = 1 THEN 1 ELSE 0 END) AS unique_pageviews",
        "SUM(CASE WHEN page_views.bounced = 1 THEN 1 ELSE 0 END) AS bounced_count",
        "COALESCE(SUM(page_views.duration), 0) AS total_duration",
        "COUNT(page_views.duration) AS duration_count"
      )
  end

  def upsert_hourly_stats(time_bucket, raw_stats)
    created = 0
    updated = 0

    raw_stats.each do |stat|
      record = HourlyPageStat.find_or_initialize_by(
        site_id: @site.id,
        hostname: stat.hostname,
        pathname: stat.pathname,
        time_bucket: time_bucket
      )

      is_new = record.new_record?

      record.assign_attributes(
        pageviews: stat.pageviews.to_i,
        visits: stat.visits.to_i,
        sessions: stat.sessions.to_i,
        unique_pageviews: stat.unique_pageviews.to_i,
        bounced_count: stat.bounced_count.to_i,
        total_duration: stat.total_duration.to_d,
        duration_count: stat.duration_count.to_i
      )

      record.save!

      is_new ? created += 1 : updated += 1
    end

    log_aggregation("hourly", time_bucket, created, updated)
    { created: created, updated: updated }
  end

  def upsert_daily_stats(date, stats)
    created = 0
    updated = 0

    stats.each do |stat|
      record = DailyPageStat.find_or_initialize_by(
        site_id: @site.id,
        hostname: stat.hostname,
        pathname: stat.pathname,
        date: date
      )

      is_new = record.new_record?

      record.assign_attributes(
        pageviews: stat.pageviews.to_i,
        visits: stat.visits.to_i,
        sessions: stat.sessions.to_i,
        unique_pageviews: stat.unique_pageviews.to_i,
        bounced_count: stat.bounced_count.to_i,
        total_duration: stat.total_duration.to_d,
        duration_count: stat.duration_count.to_i
      )

      record.save!

      is_new ? created += 1 : updated += 1
    end

    log_aggregation("daily", date.to_datetime, created, updated)
    { created: created, updated: updated }
  end

  def upsert_weekly_stats(week_start, stats)
    created = 0
    updated = 0

    stats.each do |stat|
      record = WeeklyPageStat.find_or_initialize_by(
        site_id: @site.id,
        hostname: stat.hostname,
        pathname: stat.pathname,
        week_start: week_start
      )

      is_new = record.new_record?

      record.assign_attributes(
        pageviews: stat.pageviews.to_i,
        visits: stat.visits.to_i,
        sessions: stat.sessions.to_i,
        unique_pageviews: stat.unique_pageviews.to_i,
        bounced_count: stat.bounced_count.to_i,
        total_duration: stat.total_duration.to_d,
        duration_count: stat.duration_count.to_i
      )

      record.save!

      is_new ? created += 1 : updated += 1
    end

    log_aggregation("weekly", week_start.to_datetime, created, updated)
    { created: created, updated: updated }
  end

  def log_aggregation(type, time_bucket, rows_created, rows_updated)
    AggregationLog.create!(
      site: @site,
      aggregation_type: type,
      time_bucket: time_bucket,
      rows_created: rows_created,
      rows_updated: rows_updated,
      completed_at: Time.current
    )
  end

  def round_to_hour(time)
    time.beginning_of_hour
  end

  def normalize_week_start(date)
    date = date.to_date
    date.beginning_of_week(:monday)
  end
end
