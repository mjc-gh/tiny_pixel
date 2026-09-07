# frozen_string_literal: true

class EventAggregationService
  LOOKBACK_HOURS = AggregationService::LOOKBACK_HOURS

  GRANULARITIES = {
    hourly: { model: HourlyEventStat, bucket: :time_bucket, log_type: "event_hourly" },
    daily: { model: DailyEventStat, bucket: :date, log_type: "event_daily" },
    weekly: { model: WeeklyEventStat, bucket: :week_start, log_type: "event_weekly" }
  }.freeze

  class << self
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
    reconcile(:hourly, time_bucket, time_bucket, time_bucket + 1.hour)
  end

  def aggregate_daily(date)
    date = date.to_date
    reconcile(:daily, date, date.beginning_of_day, (date + 1.day).beginning_of_day)
  end

  def aggregate_weekly(week_start)
    week_start = normalize_week_start(week_start)
    reconcile(:weekly, week_start, week_start.beginning_of_day, (week_start + 7.days).beginning_of_day)
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
    (start_date..end_date).each { |date| aggregate_daily(date) }
  end

  def aggregate_weekly_range(start_date, end_date)
    (start_date..end_date).map { |date| normalize_week_start(date) }.uniq.each { |week| aggregate_weekly(week) }
  end

  def reconcile(granularity, bucket, start_time, end_time)
    config = GRANULARITIES.fetch(granularity)
    raw_stats = fetch_raw_stats(start_time, end_time)
    key_attributes = raw_stats.to_h { |stat| [stat_key(stat), stat] }
    scope = config[:model].where(site_id: @site.id, config[:bucket] => bucket)
    existing = scope.to_a
    stale = existing.reject { |record| key_attributes.key?(record_key(record)) }
    stale.each(&:destroy!)

    created = 0
    updated = 0
    key_attributes.each_value do |stat|
      record = config[:model].find_or_initialize_by(site_id: @site.id, **record_attributes(stat, config[:bucket], bucket))
      new_record = record.new_record?
      record.assign_attributes(hits: stat.hits.to_i, unique_hits: stat.unique_hits.to_i)
      record.save!
      new_record ? created += 1 : updated += 1
    end

    log_aggregation(config[:log_type], bucket, created, updated)
    { created: created, updated: updated }
  end

  def fetch_raw_stats(start_time, end_time)
    Event
      .joins("INNER JOIN visitors ON visitors.digest = events.visitor_digest")
      .where(visitors: { property_id: @site.id })
      .where(created_at: start_time...end_time)
      .group(:name, :hostname, :pathname)
      .select(
        "events.name AS name",
        "events.hostname AS hostname",
        "events.pathname AS pathname",
        "COUNT(*) AS hits",
        "COUNT(DISTINCT events.visitor_digest) AS unique_hits"
      )
  end

  def stat_key(stat)
    [stat.name, stat.hostname, stat.pathname]
  end

  def record_key(record)
    [record.name, record.hostname, record.pathname]
  end

  def record_attributes(stat, bucket_column, bucket)
    { name: stat.name, hostname: stat.hostname, pathname: stat.pathname, bucket_column => bucket }
  end

  def log_aggregation(type, bucket, rows_created, rows_updated)
    AggregationLog.create!(
      site: @site,
      aggregation_type: type,
      time_bucket: bucket.to_datetime,
      rows_created: rows_created,
      rows_updated: rows_updated,
      completed_at: Time.current
    )
  end

  def round_to_hour(time)
    time.beginning_of_hour
  end

  def normalize_week_start(date)
    date.to_date.beginning_of_week(:monday)
  end
end
