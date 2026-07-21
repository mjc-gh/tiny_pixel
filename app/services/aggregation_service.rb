# frozen_string_literal: true

class AggregationService
  LOOKBACK_HOURS = 48
  SUPPORTED_DIMENSION_TYPES = %w[global country browser device_type referrer_hostname utm_source utm_medium utm_campaign ref].freeze
  PAGEVIEW_BASED_DIMENSIONS = %w[referrer_hostname utm_source utm_medium utm_campaign ref].freeze

  DIMENSION_EXPRESSIONS = {
    "country" => Arel.sql("visitors.country"),
    "browser" => Arel.sql("visitors.browser"),
    "device_type" => Arel.sql("visitors.device_type"),
    "referrer_hostname" => Arel.sql("referrer_hostname"),
    "utm_source" => Arel.sql("utm_source"),
    "utm_medium" => Arel.sql("utm_medium"),
    "utm_campaign" => Arel.sql("utm_campaign"),
    "ref" => Arel.sql("ref")
  }.freeze

  DIMENSION_SELECT_EXPRESSIONS = {
    "global" => Arel.sql("'global' AS dimension_value"),
    "country" => Arel.sql("visitors.country AS dimension_value"),
    "browser" => Arel.sql("visitors.browser AS dimension_value"),
    "device_type" => Arel.sql("visitors.device_type AS dimension_value"),
    "referrer_hostname" => Arel.sql("referrer_hostname AS dimension_value"),
    "utm_source" => Arel.sql("utm_source AS dimension_value"),
    "utm_medium" => Arel.sql("utm_medium AS dimension_value"),
    "utm_campaign" => Arel.sql("utm_campaign AS dimension_value"),
    "ref" => Arel.sql("ref AS dimension_value")
  }.freeze

  # Pre-built SQL templates for window functions to prevent SQL injection
  WINDOW_FUNCTION_SQL_REFERRER_HOSTNAME = <<~SQL.freeze
    WITH visit_dimensions AS (
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
      visit_dimensions.hostname AS hostname,
      visit_dimensions.pathname AS pathname,
      visit_dimensions.visit_referrer_hostname AS dimension_value,
      COUNT(*) AS pageviews,
      COUNT(DISTINCT CASE WHEN visit_dimensions.new_visit = 1 THEN visit_dimensions.visitor_digest END) AS visits,
      COUNT(DISTINCT CASE WHEN visit_dimensions.new_session = 1 THEN visit_dimensions.visitor_digest END) AS sessions,
      SUM(CASE WHEN visit_dimensions.is_unique = 1 THEN 1 ELSE 0 END) AS unique_pageviews,
      SUM(CASE WHEN visit_dimensions.bounced = 1 THEN 1 ELSE 0 END) AS bounced_count,
      COALESCE(SUM(visit_dimensions.duration), 0) AS total_duration,
      COUNT(visit_dimensions.duration) AS duration_count
    FROM visit_dimensions
    INNER JOIN visitors ON visitors.digest = visit_dimensions.visitor_digest
    WHERE visitors.property_id = ?
    GROUP BY visit_dimensions.hostname, visit_dimensions.pathname, visit_dimensions.visit_referrer_hostname
  SQL

  WINDOW_FUNCTION_SQL_UTM_SOURCE = <<~SQL.freeze
    WITH visit_dimensions AS (
      SELECT
        page_views.*,
        COALESCE(
          FIRST_VALUE(NULLIF(page_views.utm_source, '')) OVER (
            PARTITION BY page_views.visitor_digest
            ORDER BY page_views.created_at
          ),
          '(not set)'
        ) AS visit_utm_source
      FROM page_views
      WHERE page_views.created_at >= ? AND page_views.created_at < ?
    )
    SELECT
      visit_dimensions.hostname AS hostname,
      visit_dimensions.pathname AS pathname,
      visit_dimensions.visit_utm_source AS dimension_value,
      COUNT(*) AS pageviews,
      COUNT(DISTINCT CASE WHEN visit_dimensions.new_visit = 1 THEN visit_dimensions.visitor_digest END) AS visits,
      COUNT(DISTINCT CASE WHEN visit_dimensions.new_session = 1 THEN visit_dimensions.visitor_digest END) AS sessions,
      SUM(CASE WHEN visit_dimensions.is_unique = 1 THEN 1 ELSE 0 END) AS unique_pageviews,
      SUM(CASE WHEN visit_dimensions.bounced = 1 THEN 1 ELSE 0 END) AS bounced_count,
      COALESCE(SUM(visit_dimensions.duration), 0) AS total_duration,
      COUNT(visit_dimensions.duration) AS duration_count
    FROM visit_dimensions
    INNER JOIN visitors ON visitors.digest = visit_dimensions.visitor_digest
    WHERE visitors.property_id = ?
    GROUP BY visit_dimensions.hostname, visit_dimensions.pathname, visit_dimensions.visit_utm_source
  SQL

  WINDOW_FUNCTION_SQL_UTM_MEDIUM = <<~SQL.freeze
    WITH visit_dimensions AS (
      SELECT
        page_views.*,
        COALESCE(
          FIRST_VALUE(NULLIF(page_views.utm_medium, '')) OVER (
            PARTITION BY page_views.visitor_digest
            ORDER BY page_views.created_at
          ),
          '(not set)'
        ) AS visit_utm_medium
      FROM page_views
      WHERE page_views.created_at >= ? AND page_views.created_at < ?
    )
    SELECT
      visit_dimensions.hostname AS hostname,
      visit_dimensions.pathname AS pathname,
      visit_dimensions.visit_utm_medium AS dimension_value,
      COUNT(*) AS pageviews,
      COUNT(DISTINCT CASE WHEN visit_dimensions.new_visit = 1 THEN visit_dimensions.visitor_digest END) AS visits,
      COUNT(DISTINCT CASE WHEN visit_dimensions.new_session = 1 THEN visit_dimensions.visitor_digest END) AS sessions,
      SUM(CASE WHEN visit_dimensions.is_unique = 1 THEN 1 ELSE 0 END) AS unique_pageviews,
      SUM(CASE WHEN visit_dimensions.bounced = 1 THEN 1 ELSE 0 END) AS bounced_count,
      COALESCE(SUM(visit_dimensions.duration), 0) AS total_duration,
      COUNT(visit_dimensions.duration) AS duration_count
    FROM visit_dimensions
    INNER JOIN visitors ON visitors.digest = visit_dimensions.visitor_digest
    WHERE visitors.property_id = ?
    GROUP BY visit_dimensions.hostname, visit_dimensions.pathname, visit_dimensions.visit_utm_medium
  SQL

  WINDOW_FUNCTION_SQL_UTM_CAMPAIGN = <<~SQL.freeze
    WITH visit_dimensions AS (
      SELECT
        page_views.*,
        COALESCE(
          FIRST_VALUE(NULLIF(page_views.utm_campaign, '')) OVER (
            PARTITION BY page_views.visitor_digest
            ORDER BY page_views.created_at
          ),
          '(not set)'
        ) AS visit_utm_campaign
      FROM page_views
      WHERE page_views.created_at >= ? AND page_views.created_at < ?
    )
    SELECT
      visit_dimensions.hostname AS hostname,
      visit_dimensions.pathname AS pathname,
      visit_dimensions.visit_utm_campaign AS dimension_value,
      COUNT(*) AS pageviews,
      COUNT(DISTINCT CASE WHEN visit_dimensions.new_visit = 1 THEN visit_dimensions.visitor_digest END) AS visits,
      COUNT(DISTINCT CASE WHEN visit_dimensions.new_session = 1 THEN visit_dimensions.visitor_digest END) AS sessions,
      SUM(CASE WHEN visit_dimensions.is_unique = 1 THEN 1 ELSE 0 END) AS unique_pageviews,
      SUM(CASE WHEN visit_dimensions.bounced = 1 THEN 1 ELSE 0 END) AS bounced_count,
      COALESCE(SUM(visit_dimensions.duration), 0) AS total_duration,
      COUNT(visit_dimensions.duration) AS duration_count
    FROM visit_dimensions
    INNER JOIN visitors ON visitors.digest = visit_dimensions.visitor_digest
    WHERE visitors.property_id = ?
    GROUP BY visit_dimensions.hostname, visit_dimensions.pathname, visit_dimensions.visit_utm_campaign
  SQL

  WINDOW_FUNCTION_SQL_REF = <<~SQL.freeze
    WITH visit_dimensions AS (
      SELECT
        page_views.*,
        COALESCE(
          FIRST_VALUE(NULLIF(page_views.ref, '')) OVER (
            PARTITION BY page_views.visitor_digest
            ORDER BY page_views.created_at
          ),
          '(not set)'
        ) AS visit_ref
      FROM page_views
      WHERE page_views.created_at >= ? AND page_views.created_at < ?
    )
    SELECT
      visit_dimensions.hostname AS hostname,
      visit_dimensions.pathname AS pathname,
      visit_dimensions.visit_ref AS dimension_value,
      COUNT(*) AS pageviews,
      COUNT(DISTINCT CASE WHEN visit_dimensions.new_visit = 1 THEN visit_dimensions.visitor_digest END) AS visits,
      COUNT(DISTINCT CASE WHEN visit_dimensions.new_session = 1 THEN visit_dimensions.visitor_digest END) AS sessions,
      SUM(CASE WHEN visit_dimensions.is_unique = 1 THEN 1 ELSE 0 END) AS unique_pageviews,
      SUM(CASE WHEN visit_dimensions.bounced = 1 THEN 1 ELSE 0 END) AS bounced_count,
      COALESCE(SUM(visit_dimensions.duration), 0) AS total_duration,
      COUNT(visit_dimensions.duration) AS duration_count
    FROM visit_dimensions
    INNER JOIN visitors ON visitors.digest = visit_dimensions.visitor_digest
    WHERE visitors.property_id = ?
    GROUP BY visit_dimensions.hostname, visit_dimensions.pathname, visit_dimensions.visit_ref
  SQL

  # Map dimension types to their pre-built SQL templates
  WINDOW_FUNCTION_SQL = {
    "referrer_hostname" => WINDOW_FUNCTION_SQL_REFERRER_HOSTNAME,
    "utm_source" => WINDOW_FUNCTION_SQL_UTM_SOURCE,
    "utm_medium" => WINDOW_FUNCTION_SQL_UTM_MEDIUM,
    "utm_campaign" => WINDOW_FUNCTION_SQL_UTM_CAMPAIGN,
    "ref" => WINDOW_FUNCTION_SQL_REF
  }.freeze

  private_constant :WINDOW_FUNCTION_SQL

  class << self
    def aggregate_all_sites(lookback_hours: LOOKBACK_HOURS)
      Site.find_each do |site|
        new(site).aggregate_recent(lookback_hours: lookback_hours)
      end
    end

    def dimension_expression_for_type(dimension_type)
      DIMENSION_EXPRESSIONS[dimension_type]
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

  def aggregate_hourly(time_bucket, dimension_type: "global")
    time_bucket = round_to_hour(time_bucket)
    bucket_end = time_bucket + 1.hour

    raw_stats = fetch_raw_stats(time_bucket, bucket_end, dimension_type: dimension_type)
    return { created: 0, updated: 0 } if raw_stats.empty?

    upsert_hourly_stats(time_bucket, raw_stats, dimension_type: dimension_type)
  end

  def aggregate_daily(date, dimension_type: "global")
    date = date.to_date
    start_time = date.beginning_of_day
    end_time = (date + 1.day).beginning_of_day

    raw_stats = fetch_raw_stats(start_time, end_time, dimension_type: dimension_type)
    return { created: 0, updated: 0 } if raw_stats.empty?

    upsert_daily_stats(date, raw_stats, dimension_type: dimension_type)
  end

  def aggregate_weekly(week_start, dimension_type: "global")
    week_start = normalize_week_start(week_start)
    start_time = week_start.beginning_of_day
    end_time = (week_start + 7.days).beginning_of_day

    raw_stats = fetch_raw_stats(start_time, end_time, dimension_type: dimension_type)
    return { created: 0, updated: 0 } if raw_stats.empty?

    upsert_weekly_stats(week_start, raw_stats, dimension_type: dimension_type)
  end

  def aggregate_all_dimensions_hourly(time_bucket)
    aggregate_hourly(time_bucket, dimension_type: "global")

    %w[country browser device_type referrer_hostname utm_source utm_medium utm_campaign ref].each do |dim_type|
      aggregate_hourly(time_bucket, dimension_type: dim_type)
    end
  end

  def aggregate_all_dimensions_daily(date)
    aggregate_daily(date, dimension_type: "global")

    %w[country browser device_type referrer_hostname utm_source utm_medium utm_campaign ref].each do |dim_type|
      aggregate_daily(date, dimension_type: dim_type)
    end
  end

  def aggregate_all_dimensions_weekly(week_start)
    aggregate_weekly(week_start, dimension_type: "global")

    %w[country browser device_type referrer_hostname utm_source utm_medium utm_campaign ref].each do |dim_type|
      aggregate_weekly(week_start, dimension_type: dim_type)
    end
  end

  private

  def aggregate_hourly_range(start_time, end_time)
    current = round_to_hour(start_time)

    while current < end_time
      aggregate_all_dimensions_hourly(current)
      current += 1.hour
    end
  end

  def aggregate_daily_range(start_date, end_date)
    (start_date..end_date).each do |date|
      aggregate_all_dimensions_daily(date)
    end
  end

  def aggregate_weekly_range(start_date, end_date)
    week_starts = (start_date..end_date).map { |d| normalize_week_start(d) }.uniq

    week_starts.each do |week_start|
      aggregate_all_dimensions_weekly(week_start)
    end
  end

  def fetch_raw_stats(start_time, end_time, dimension_type: "global")
    dimension_expression = self.class.dimension_expression_for_type(dimension_type) if dimension_type != "global"

    # For pageview-based dimensions, we need special handling with a window function
    if dimension_type.in?(PAGEVIEW_BASED_DIMENSIONS)
      fetch_raw_stats_with_window_function(start_time, end_time, dimension_type)
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
      group_columns << dimension_expression
    end

    dimension_select = DIMENSION_SELECT_EXPRESSIONS[dimension_type] || DIMENSION_SELECT_EXPRESSIONS["global"]

    query
      .group(*group_columns)
      .select(
        "page_views.hostname AS hostname",
        "page_views.pathname AS pathname",
        dimension_select,
        "COUNT(*) AS pageviews",
        "COUNT(DISTINCT CASE WHEN page_views.new_visit = 1 THEN page_views.visitor_digest END) AS visits",
        "COUNT(DISTINCT CASE WHEN page_views.new_session = 1 THEN page_views.visitor_digest END) AS sessions",
        "SUM(CASE WHEN page_views.is_unique = 1 THEN 1 ELSE 0 END) AS unique_pageviews",
        "SUM(CASE WHEN page_views.bounced = 1 THEN 1 ELSE 0 END) AS bounced_count",
        "COALESCE(SUM(page_views.duration), 0) AS total_duration",
        "COUNT(page_views.duration) AS duration_count"
      )
  end

  def fetch_raw_stats_with_window_function(start_time, end_time, dimension_type)
    # Use a CTE with FIRST_VALUE window function to propagate pageview-based dimensions from
    # the first page view of each visit to all page views in that visit

    # Use pre-built static SQL templates for SQL injection safety
    cte_sql = WINDOW_FUNCTION_SQL[dimension_type]
    raise ArgumentError, "Invalid dimension_type: #{dimension_type}" if cte_sql.nil?

    result = PageView.connection.select_all(cte_sql, "AggregationService", [start_time, end_time, @site.id])
    # Convert Hash objects to OpenStruct to provide dot notation access for method calls
    result.map { |row| OpenStruct.new(row.to_h) }
  end

  private

  def upsert_hourly_stats(time_bucket, raw_stats, dimension_type: "global")
    created = 0
    updated = 0

    raw_stats.each do |stat|
      dimension_value = dimension_type == "global" ? nil : stat.dimension_value

      record = HourlyPageStat.find_or_initialize_by(
        site_id: @site.id,
        hostname: stat.hostname,
        pathname: stat.pathname,
        dimension_type: dimension_type,
        dimension_value: dimension_value,
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

  def upsert_daily_stats(date, stats, dimension_type: "global")
    created = 0
    updated = 0

    stats.each do |stat|
      dimension_value = dimension_type == "global" ? nil : stat.dimension_value

      record = DailyPageStat.find_or_initialize_by(
        site_id: @site.id,
        hostname: stat.hostname,
        pathname: stat.pathname,
        dimension_type: dimension_type,
        dimension_value: dimension_value,
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

  def upsert_weekly_stats(week_start, stats, dimension_type: "global")
    created = 0
    updated = 0

    stats.each do |stat|
      dimension_value = dimension_type == "global" ? nil : stat.dimension_value

      record = WeeklyPageStat.find_or_initialize_by(
        site_id: @site.id,
        hostname: stat.hostname,
        pathname: stat.pathname,
        dimension_type: dimension_type,
        dimension_value: dimension_value,
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
