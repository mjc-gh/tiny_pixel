# frozen_string_literal: true

# Configuration Constants
HOSTNAME = "example.com"
PATHNAMES = ["/", "/about", "/blog", "/blog/post-1", "/blog/post-2", "/contact", "/pricing"].freeze
REFERRERS = ["https://google.com", "https://twitter.com", "https://news.ycombinator.com", nil].freeze
BROWSERS = %i[chrome firefox safari edge opera].freeze
DEVICE_TYPES = %i[desktop mobile].freeze
COUNTRIES = %w[US GB DE FR CA AU JP].freeze

AGGREGATED_DATA_DAYS = 14
VISITOR_COUNT = 75

# Helper Methods

def create_visitor(site, index)
  digest = Digest::SHA256.hexdigest("visitor-#{site.id}-#{index}-#{Time.current.to_i}")

  Visitor.create!(
    digest: digest,
    property_id: site.id,
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

# Create Visitors and PageViews (14 days of raw data)
puts "Creating visitors and page views for test site..."

end_date = Time.current.beginning_of_day - 1.day
start_date = end_date - AGGREGATED_DATA_DAYS.days

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

# Aggregate stats using AggregationService
puts "\nAggregating stats for test site using AggregationService..."

aggregated_end_date = Date.current - 1.day
aggregated_start_date = aggregated_end_date - AGGREGATED_DATA_DAYS.days

service = AggregationService.new(site)

# Aggregate hourly stats
(aggregated_start_date..aggregated_end_date).each do |date|
  24.times do |hour|
    time_bucket = Time.zone.local(date.year, date.month, date.day, hour)
    service.aggregate_all_dimensions_hourly(time_bucket)
  end
end

# Aggregate daily stats
(aggregated_start_date..aggregated_end_date).each do |date|
  service.aggregate_all_dimensions_daily(date)
end

# Aggregate weekly stats
week_starts = (aggregated_start_date..aggregated_end_date).map { |d| d.beginning_of_week(:monday) }.uniq
week_starts.each { |week_start| service.aggregate_all_dimensions_weekly(week_start) }

hourly_count = site.hourly_page_stats.count
daily_count = site.daily_page_stats.count
weekly_count = site.weekly_page_stats.count

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
PageView.where(hostname: ["app.example.com", "docs.example.com", "blog.example.com"]).delete_all
Visitor.where(property_id: multi_site.id).delete_all

# Create Visitors and PageViews for multi-domain site
puts "Creating visitors and page views for multi-domain site..."

multi_hostnames = ["app.example.com", "docs.example.com", "blog.example.com"].freeze
multi_visitors = []
VISITOR_COUNT.times do |i|
  multi_visitors << create_visitor(multi_site, i)
end

multi_page_view_count = 0
multi_visitors.each do |visitor|
  session_count = rand(1..5)
  first_session = true

  session_count.times do
    session_start = rand(start_date..end_date)
    page_count = rand(1..6)
    first_page = true
    session_pages = PATHNAMES.sample(page_count)
    hostname = multi_hostnames.sample

    session_pages.each_with_index do |pathname, idx|
      timestamp = session_start + (idx * rand(30..300)).seconds
      is_last_page = idx == session_pages.length - 1
      bounced = page_count == 1

      create_page_view(
        visitor,
        timestamp,
        hostname: hostname,
        pathname: pathname,
        referrer: first_page && rand < 0.4 ? REFERRERS.compact.sample : nil,
        is_unique: first_session && first_page,
        new_session: first_page,
        new_visit: first_session && first_page,
        bounced: bounced,
        duration: is_last_page ? nil : rand(10..300)
      )
      multi_page_view_count += 1
      first_page = false
    end

    first_session = false
  end
end

puts "Created #{multi_visitors.count} visitors for multi-domain site"
puts "Created #{multi_page_view_count} page views for multi-domain site"

# Aggregate stats for multi-domain site using AggregationService
puts "Aggregating stats for multi-domain site using AggregationService..."

multi_service = AggregationService.new(multi_site)

# Aggregate hourly stats
(aggregated_start_date..aggregated_end_date).each do |date|
  24.times do |hour|
    time_bucket = Time.zone.local(date.year, date.month, date.day, hour)
    multi_service.aggregate_all_dimensions_hourly(time_bucket)
  end
end

# Aggregate daily stats
(aggregated_start_date..aggregated_end_date).each do |date|
  multi_service.aggregate_all_dimensions_daily(date)
end

# Aggregate weekly stats
week_starts.each { |week_start| multi_service.aggregate_all_dimensions_weekly(week_start) }

multi_hourly_count = multi_site.hourly_page_stats.count
multi_daily_count = multi_site.daily_page_stats.count
multi_weekly_count = multi_site.weekly_page_stats.count

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
