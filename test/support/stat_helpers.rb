# frozen_string_literal: true

module StatHelpers
  DEFAULT_STAT_ATTRS = {
    hostname: "example.com",
    pathname: "/",
    pageviews: 100,
    unique_pageviews: 50,
    visits: 40,
    sessions: 30,
    bounced_count: 20,
    total_duration: 120.5,
    duration_count: 30
  }.freeze

  def create_daily_stat(site, **attrs)
    defaults = DEFAULT_STAT_ATTRS.merge(date: Date.current)
    DailyPageStat.create!(site:, **defaults.merge(attrs))
  end

  def create_hourly_stat(site, **attrs)
    defaults = DEFAULT_STAT_ATTRS.merge(time_bucket: Time.current.change(min: 0, sec: 0))
    HourlyPageStat.create!(site:, **defaults.merge(attrs))
  end

  def create_weekly_stat(site, **attrs)
    defaults = DEFAULT_STAT_ATTRS.merge(week_start: Date.current.beginning_of_week)
    WeeklyPageStat.create!(site:, **defaults.merge(attrs))
  end

  def create_daily_stat_with_dimension(site, dimension_type:, dimension_value:, **attrs)
    create_daily_stat(site, dimension_type:, dimension_value:, **attrs)
  end

  def create_hourly_stat_with_dimension(site, dimension_type:, dimension_value:, **attrs)
    create_hourly_stat(site, dimension_type:, dimension_value:, **attrs)
  end

  def create_weekly_stat_with_dimension(site, dimension_type:, dimension_value:, **attrs)
    create_weekly_stat(site, dimension_type:, dimension_value:, **attrs)
  end

  def create_daily_stats_range(site, start_date:, end_date:, **attrs)
    stats = []
    (start_date..end_date).each do |date|
      stats << create_daily_stat(site, date:, **attrs)
    end
    stats
  end

  def build_pageview_stat(**attrs)
    defaults = {
      hostname: "example.com",
      pathname: "/",
      pageviews: 100,
      unique_pageviews: 50,
      visits: 40,
      sessions: 30,
      bounced_count: 20,
      total_duration: 120.5,
      duration_count: 30
    }
    PageviewStat.new(**defaults.merge(attrs))
  end
end
