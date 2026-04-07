# frozen_string_literal: true

# Configuration Constants
HOSTNAME = "example.com"
PATHNAMES = ["/", "/about", "/blog", "/blog/post-1", "/blog/post-2", "/contact", "/pricing"].freeze
REFERRERS = ["https://google.com", "https://twitter.com", "https://news.ycombinator.com", nil].freeze
BROWSERS = %i[chrome firefox safari edge opera].freeze
DEVICE_TYPES = %i[desktop mobile].freeze
COUNTRIES = %w[US GB DE FR CA AU JP].freeze

RAW_DATA_DAYS = 7
AGGREGATED_DATA_DAYS = 14
VISITOR_COUNT = 75

# Helper Methods

def create_visitor(site, index)
  digest = Digest::SHA256.hexdigest("visitor-#{site.property_id}-#{index}-#{Time.current.to_i}")

  Visitor.create!(
    digest: digest,
    property_id: site.property_id,
    browser: BROWSERS.sample,
    device_type: DEVICE_TYPES.sample,
    country: COUNTRIES.sample,
    salt_version: site.salt_version
  )
end

def create_page_view(visitor, timestamp, options = {})
  digest = Digest::SHA256.hexdigest("pageview-#{visitor.digest}-#{timestamp.to_i}-#{rand(100_000)}")
  referrer = options[:referrer]
  referrer_hostname = nil
  referrer_pathname = nil

  if referrer
    uri = URI.parse(referrer)
    referrer_hostname = uri.host
    referrer_pathname = uri.path.presence || "/"
  end

  PageView.create!(
    digest: digest,
    visitor_digest: visitor.digest,
    hostname: options[:hostname] || HOSTNAME,
    pathname: options[:pathname] || PATHNAMES.sample,
    referrer: referrer,
    referrer_hostname: referrer_hostname,
    referrer_pathname: referrer_pathname,
    is_unique: options.fetch(:is_unique, false),
    new_session: options.fetch(:new_session, false),
    new_visit: options.fetch(:new_visit, false),
    bounced: options.fetch(:bounced, true),
    duration: options[:duration],
    created_at: timestamp
  )
end

def random_metrics(base_pageviews)
  pageviews = base_pageviews
  unique_pageviews = [pageviews, (pageviews * rand(0.6..0.9)).round].min
  sessions = [unique_pageviews, (unique_pageviews * rand(0.7..0.95)).round].min
  visits = [sessions, (sessions * rand(0.5..0.85)).round].min
  bounced_count = (visits * rand(0.2..0.5)).round
  duration_count = (pageviews * rand(0.6..0.8)).round
  total_duration = duration_count * rand(30..180)

  {
    pageviews: pageviews,
    unique_pageviews: unique_pageviews,
    sessions: sessions,
    visits: visits,
    bounced_count: bounced_count,
    total_duration: total_duration,
    duration_count: duration_count
  }
end

def create_hourly_stat(site, hostname, pathname, time_bucket, metrics)
  HourlyPageStat.create!(
    site: site,
    hostname: hostname,
    pathname: pathname,
    time_bucket: time_bucket,
    **metrics
  )
end

def create_daily_stat(site, hostname, pathname, date, metrics)
  DailyPageStat.create!(
    site: site,
    hostname: hostname,
    pathname: pathname,
    date: date,
    **metrics
  )
end

def create_weekly_stat(site, hostname, pathname, week_start, metrics)
  WeeklyPageStat.create!(
    site: site,
    hostname: hostname,
    pathname: pathname,
    week_start: week_start,
    **metrics
  )
end

def hourly_traffic_multiplier(hour)
  case hour
  when 0..5 then rand(0.1..0.3)
  when 6..8 then rand(0.4..0.6)
  when 9..11 then rand(0.8..1.0)
  when 12..14 then rand(0.9..1.2)
  when 15..17 then rand(0.7..0.9)
  when 18..20 then rand(0.5..0.7)
  else rand(0.2..0.4)
  end
end

# Seed Execution

puts "Seeding database..."

# Create or find Site
site = Site.find_by(name: "Test Site") || Site.create!(name: "Test Site", salt: "testsalt")
puts "Using site: #{site.name} (#{site.property_id})"

# Create or find User and Membership
user = User.find_or_create_by!(email: "test@example.com") do |u|
  u.password = "thisisapassword"
  u.confirmed_at = Time.current
end
puts "Using user: #{user.email}"

membership = Membership.find_or_create_by!(user: user, site: site) do |m|
  m.role = :admin
end
puts "Using membership: #{user.email} -> #{site.name} (#{membership.role})"

# Clear existing seed data for idempotent re-runs
puts "Clearing existing seed data..."
site.hourly_page_stats.delete_all
site.daily_page_stats.delete_all
site.weekly_page_stats.delete_all
PageView.delete_all
Visitor.delete_all
puts "Cleared existing data"

# Create Visitors and PageViews (7 days of raw data)
puts "Creating visitors and page views..."

end_date = Time.current.beginning_of_day - 1.day
start_date = end_date - RAW_DATA_DAYS.days

visitors = []
VISITOR_COUNT.times do |i|
  visitors << create_visitor(site, i)
end

page_view_count = 0
visitors.each do |visitor|
  session_count = rand(1..5)
  first_session = true

  session_count.times do
    session_start = rand(start_date..end_date)
    page_count = rand(1..6)
    first_page = true
    session_pages = PATHNAMES.sample(page_count)

    session_pages.each_with_index do |pathname, idx|
      timestamp = session_start + (idx * rand(30..300)).seconds
      is_last_page = idx == session_pages.length - 1
      bounced = page_count == 1

      create_page_view(
        visitor,
        timestamp,
        hostname: HOSTNAME,
        pathname: pathname,
        referrer: first_page && rand < 0.4 ? REFERRERS.compact.sample : nil,
        is_unique: first_session && first_page,
        new_session: first_page,
        new_visit: first_session && first_page,
        bounced: bounced,
        duration: is_last_page ? nil : rand(10..300)
      )
      page_view_count += 1
      first_page = false
    end

    first_session = false
  end
end

puts "Created #{visitors.count} visitors"
puts "Created #{page_view_count} page views"

# Calculate aggregation date range
aggregated_end_date = Date.current - 1.day
aggregated_start_date = aggregated_end_date - AGGREGATED_DATA_DAYS.days

# Create Aggregated Stats (14 days)
puts "\nCreating aggregated stats for test site..."

hourly_count = 0
daily_count = 0
weekly_count = 0

# Track daily totals for weekly aggregation
weekly_totals = Hash.new { |h, k| h[k] = Hash.new(0) }

(aggregated_start_date..aggregated_end_date).each do |date|
  week_start = date.beginning_of_week(:monday)
  daily_totals = Hash.new { |h, k| h[k] = Hash.new(0) }

  # Create hourly stats
  24.times do |hour|
    time_bucket = Time.zone.local(date.year, date.month, date.day, hour)
    multiplier = hourly_traffic_multiplier(hour)

    PATHNAMES.each do |pathname|
      base_pageviews = (rand(5..20) * multiplier).round
      next if base_pageviews.zero?

      metrics = random_metrics(base_pageviews)
      create_hourly_stat(site, HOSTNAME, pathname, time_bucket, metrics)
      hourly_count += 1

      # Accumulate daily totals
      metrics.each { |k, v| daily_totals[pathname][k] += v }
    end
  end

  # Create daily stats from accumulated hourly totals
  PATHNAMES.each do |pathname|
    totals = daily_totals[pathname]
    next if totals[:pageviews].zero?

    create_daily_stat(site, HOSTNAME, pathname, date, totals)
    daily_count += 1

    # Accumulate weekly totals
    totals.each { |k, v| weekly_totals[[week_start, pathname]][k] += v }
  end
end

# Create weekly stats from accumulated daily totals
weekly_totals.each do |(week_start, pathname), totals|
  next if totals[:pageviews].zero?

  create_weekly_stat(site, HOSTNAME, pathname, week_start, totals)
  weekly_count += 1
end

puts "Created #{hourly_count} hourly page stats"
puts "Created #{daily_count} daily page stats"
puts "Created #{weekly_count} weekly page stats"

# Create Multi-Domain Site
puts "\nCreating multi-domain site..."

multi_site = Site.find_by(name: "Multi-Domain Site") || Site.create!(
  name: "Multi-Domain Site",
  salt: SecureRandom.urlsafe_base64(32),
  display_hostname: true
)
puts "Using multi-domain site: #{multi_site.name} (#{multi_site.property_id})"

# Ensure user has membership for multi-site
Membership.find_or_create_by!(user: user, site: multi_site) do |m|
  m.role = :admin
end

# Clear existing seed data for multi-site idempotent re-runs
multi_site.hourly_page_stats.delete_all
multi_site.daily_page_stats.delete_all
multi_site.weekly_page_stats.delete_all

# Create stats for multi-domain site
puts "Creating multi-domain site aggregated stats..."

multi_hostnames = ["app.example.com", "docs.example.com", "blog.example.com"].freeze
multi_hourly_count = 0
multi_daily_count = 0
multi_weekly_count = 0

# Track daily and weekly totals for multi-site
multi_weekly_totals = Hash.new { |h, k| h[k] = Hash.new(0) }

(aggregated_start_date..aggregated_end_date).each do |date|
  week_start = date.beginning_of_week(:monday)
  multi_daily_totals = Hash.new { |h, k| h[k] = Hash.new(0) }

  # Create hourly stats for each hostname
  24.times do |hour|
    time_bucket = Time.zone.local(date.year, date.month, date.day, hour)
    multiplier = hourly_traffic_multiplier(hour)

    multi_hostnames.each do |hostname|
      PATHNAMES.each do |pathname|
        base_pageviews = (rand(3..15) * multiplier).round
        next if base_pageviews.zero?

        metrics = random_metrics(base_pageviews)
        create_hourly_stat(multi_site, hostname, pathname, time_bucket, metrics)
        multi_hourly_count += 1

        # Accumulate daily totals
        metrics.each { |k, v| multi_daily_totals[[hostname, pathname]][k] += v }
      end
    end
  end

  # Create daily stats from accumulated hourly totals
  multi_hostnames.each do |hostname|
    PATHNAMES.each do |pathname|
      totals = multi_daily_totals[[hostname, pathname]]
      next if totals[:pageviews].zero?

      create_daily_stat(multi_site, hostname, pathname, date, totals)
      multi_daily_count += 1

      # Accumulate weekly totals
      totals.each { |k, v| multi_weekly_totals[[week_start, hostname, pathname]][k] += v }
    end
  end
end

# Create weekly stats from accumulated daily totals
multi_weekly_totals.each do |(week_start, hostname, pathname), totals|
  next if totals[:pageviews].zero?

  create_weekly_stat(multi_site, hostname, pathname, week_start, totals)
  multi_weekly_count += 1
end

puts "Created #{multi_hourly_count} hourly page stats for multi-domain site"
puts "Created #{multi_daily_count} daily page stats for multi-domain site"
puts "Created #{multi_weekly_count} weekly page stats for multi-domain site"

puts "\nSeeding complete!"
puts "Total records:"
puts "  - Sites: #{Site.count}"
puts "  - Users: #{User.count}"
puts "  - Memberships: #{Membership.count}"
puts "  - Visitors: #{Visitor.count}"
puts "  - PageViews: #{PageView.count}"
puts "  - HourlyPageStats: #{HourlyPageStat.count}"
puts "  - DailyPageStats: #{DailyPageStat.count}"
puts "  - WeeklyPageStats: #{WeeklyPageStat.count}"
