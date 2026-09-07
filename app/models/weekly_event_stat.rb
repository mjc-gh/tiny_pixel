# frozen_string_literal: true

# == Schema Information
#
# Table name: weekly_event_stats
# Database name: primary
#
#  id          :integer          not null, primary key
#  hits        :integer          default(0), not null
#  hostname    :string           not null
#  name        :string           not null
#  pathname    :string           not null
#  unique_hits :integer          default(0), not null
#  week_start  :date             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  site_id     :integer          not null
#
# Indexes
#
#  idx_weekly_event_stats_site_host_time  (site_id,hostname,week_start)
#  idx_weekly_event_stats_site_name_time  (site_id,name,week_start)
#  idx_weekly_event_stats_site_time       (site_id,week_start)
#  idx_weekly_event_stats_unique          (site_id,name,hostname,pathname,week_start) UNIQUE
#  index_weekly_event_stats_on_site_id    (site_id)
#
# Foreign Keys
#
#  site_id  (site_id => sites.id)
#
class WeeklyEventStat < ApplicationRecord
  belongs_to :site

  scope :for_site, ->(site_id) { where(site_id: site_id) }
  scope :for_date_range, ->(start_date, end_date) {
    range = if start_date && end_date
      start_date..end_date
    elsif start_date
      start_date..
    elsif end_date
      ..end_date
    end
    where(week_start: range) if range
  }
  scope :for_hostname, ->(hostname) { where(hostname: hostname) }
  scope :for_pathname, ->(pathname) { where(pathname: pathname) }
  scope :for_name, ->(name) { where(name: name) }
  scope :ordered_by_hits, -> { order(hits: :desc) }
  scope :ordered_by_week, -> { order(week_start: :desc) }
  scope :older_than, ->(cutoff) { where(week_start: ...cutoff.to_date) }

  validates :name, :hostname, :pathname, :week_start, presence: true
end
