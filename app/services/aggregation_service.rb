# frozen_string_literal: true

class AggregationService
  LOOKBACK_HOURS = 48

  class << self
    def aggregate_all_sites(lookback_hours: LOOKBACK_HOURS)
      Site.find_each do |site|
        new(site).aggregate_recent(lookback_hours: lookback_hours)
      end
    end

    def dimension_expression_for_type(dimension_type)
      case dimension_type
      when "country"
        "visitors.country"
      when "browser"
        "visitors.browser"
      when "device_type"
        "visitors.device_type"
      when "referrer_hostname"
        "referrer_hostname"
      else
        nil
      end
    end

    def format_dimension_value(dimension, raw_value)
      return "global" if dimension == "global"

      dimension_type = dimension.split(":").first
      "#{dimension_type}:#{raw_value}"
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

  def aggregate_hourly(time_bucket, dimension: "global")
    time_bucket = round_to_hour(time_bucket)
    bucket_end = time_bucket + 1.hour

    raw_stats = fetch_raw_stats(time_bucket, bucket_end, dimension: dimension)
    return { created: 0, updated: 0 } if raw_stats.empty?

    upsert_hourly_stats(time_bucket, raw_stats, dimension: dimension)
  end

  def aggregate_daily(date, dimension: "global")
    date = date.to_date
    start_time = date.beginning_of_day
    end_time = (date + 1.day).beginning_of_day

    raw_stats = fetch_raw_stats(start_time, end_time, dimension: dimension)
    return { created: 0, updated: 0 } if raw_stats.empty?

    upsert_daily_stats(date, raw_stats, dimension: dimension)
  end

  def aggregate_weekly(week_start, dimension: "global")
    week_start = normalize_week_start(week_start)
    start_time = week_start.beginning_of_day
    end_time = (week_start + 7.days).beginning_of_day

    raw_stats = fetch_raw_stats(start_time, end_time, dimension: dimension)
    return { created: 0, updated: 0 } if raw_stats.empty?

    upsert_weekly_stats(week_start, raw_stats, dimension: dimension)
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

  def fetch_raw_stats(start_time, end_time, dimension: "global")
    dimension_type = dimension == "global" ? nil : dimension.split(":").first
    dimension_expression = self.class.dimension_expression_for_type(dimension_type) if dimension_type

    # For referrer_hostname, we need special handling with a window function
    if dimension_type == "referrer_hostname"
      fetch_raw_stats_with_window_function(start_time, end_time, dimension_expression)
    else
      fetch_raw_stats_standard(start_time, end_time, dimension_expression, dimension_type)
    end
  end

  def fetch_raw_stats_standard(start_time, end_time, dimension_expression, dimension_type)
    query = PageView
      .joins("INNER JOIN visitors ON visitors.digest = page_views.visitor_digest")
      .where("visitors.property_id = ?", @site.id)
      .where(created_at: start_time...end_time)

    # Determine grouping based on dimension
    group_columns = [:hostname, :pathname]

    if dimension_expression
      group_columns << Arel.sql(dimension_expression)
    end

    query
      .group(*group_columns)
      .select(
        "page_views.hostname AS hostname",
        "page_views.pathname AS pathname",
        dimension_expression ? "#{dimension_expression} AS dimension_value" : "'global' AS dimension_value",
        "COUNT(*) AS pageviews",
        "COUNT(DISTINCT CASE WHEN page_views.new_visit = 1 THEN page_views.visitor_digest END) AS visits",
        "COUNT(DISTINCT CASE WHEN page_views.new_session = 1 THEN page_views.visitor_digest END) AS sessions",
        "SUM(CASE WHEN page_views.is_unique = 1 THEN 1 ELSE 0 END) AS unique_pageviews",
        "SUM(CASE WHEN page_views.bounced = 1 THEN 1 ELSE 0 END) AS bounced_count",
        "COALESCE(SUM(page_views.duration), 0) AS total_duration",
        "COUNT(page_views.duration) AS duration_count"
      )
  end

  def fetch_raw_stats_with_window_function(start_time, end_time, dimension_expression)
    # Use a CTE with FIRST_VALUE window function to propagate referrer_hostname from
    # the first page view of each visit to all page views in that visit
    cte_sql = <<~SQL
      WITH visit_referrers AS (
        SELECT
          page_views.*,
          COALESCE(
            FIRST_VALUE(NULLIF(page_views.referrer_hostname, '')) OVER (
              PARTITION BY page_views.visitor_digest
              ORDER BY page_views.created_at
            ),
            'direct'
          ) AS visit_referrer_hostname
        FROM page_views
        WHERE page_views.created_at >= ? AND page_views.created_at < ?
      )
      SELECT
        visit_referrers.hostname AS hostname,
        visit_referrers.pathname AS pathname,
        visit_referrers.visit_referrer_hostname AS dimension_value,
        COUNT(*) AS pageviews,
        COUNT(DISTINCT CASE WHEN visit_referrers.new_visit = 1 THEN visit_referrers.visitor_digest END) AS visits,
        COUNT(DISTINCT CASE WHEN visit_referrers.new_session = 1 THEN visit_referrers.visitor_digest END) AS sessions,
        SUM(CASE WHEN visit_referrers.is_unique = 1 THEN 1 ELSE 0 END) AS unique_pageviews,
        SUM(CASE WHEN visit_referrers.bounced = 1 THEN 1 ELSE 0 END) AS bounced_count,
        COALESCE(SUM(visit_referrers.duration), 0) AS total_duration,
        COUNT(visit_referrers.duration) AS duration_count
      FROM visit_referrers
      INNER JOIN visitors ON visitors.digest = visit_referrers.visitor_digest
      WHERE visitors.property_id = ?
      GROUP BY visit_referrers.hostname, visit_referrers.pathname, visit_referrers.visit_referrer_hostname
    SQL

    result = PageView.connection.select_all(cte_sql, "AggregationService", [start_time, end_time, @site.id])
    # Convert Hash objects to OpenStruct to provide dot notation access for method calls
    result.map { |row| OpenStruct.new(row.to_h) }
  end

  def upsert_hourly_stats(time_bucket, raw_stats, dimension: "global")
    created = 0
    updated = 0

    raw_stats.each do |stat|
      dimension_value = self.class.format_dimension_value(dimension, stat.dimension_value)

      record = HourlyPageStat.find_or_initialize_by(
        site_id: @site.id,
        hostname: stat.hostname,
        pathname: stat.pathname,
        dimension: dimension_value,
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

  def upsert_daily_stats(date, stats, dimension: "global")
    created = 0
    updated = 0

    stats.each do |stat|
      dimension_value = self.class.format_dimension_value(dimension, stat.dimension_value)

      record = DailyPageStat.find_or_initialize_by(
        site_id: @site.id,
        hostname: stat.hostname,
        pathname: stat.pathname,
        dimension: dimension_value,
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

  def upsert_weekly_stats(week_start, stats, dimension: "global")
    created = 0
    updated = 0

    stats.each do |stat|
      dimension_value = self.class.format_dimension_value(dimension, stat.dimension_value)

      record = WeeklyPageStat.find_or_initialize_by(
        site_id: @site.id,
        hostname: stat.hostname,
        pathname: stat.pathname,
        dimension: dimension_value,
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
