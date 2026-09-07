# frozen_string_literal: true

# == Schema Information
#
# Table name: hourly_event_stats
# Database name: primary
#
#  id          :integer          not null, primary key
#  hits        :integer          default(0), not null
#  hostname    :string           not null
#  name        :string           not null
#  pathname    :string           not null
#  time_bucket :datetime         not null
#  unique_hits :integer          default(0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  site_id     :integer          not null
#
# Indexes
#
#  idx_hourly_event_stats_site_host_time  (site_id,hostname,time_bucket)
#  idx_hourly_event_stats_site_name_time  (site_id,name,time_bucket)
#  idx_hourly_event_stats_site_time       (site_id,time_bucket)
#  idx_hourly_event_stats_unique          (site_id,name,hostname,pathname,time_bucket) UNIQUE
#  index_hourly_event_stats_on_site_id    (site_id)
#
# Foreign Keys
#
#  site_id  (site_id => sites.id)
#
class HourlyEventStat < ApplicationRecord
  belongs_to :site

  scope :for_site, ->(site_id) { where(site_id: site_id) }
  scope :for_date_range, ->(start_time, end_time) {
    range = if start_time && end_time
      start_time..end_time
    elsif start_time
      start_time..
    elsif end_time
      ..end_time
    end
    where(time_bucket: range) if range
  }
  scope :for_hostname, ->(hostname) { where(hostname: hostname) }
  scope :for_pathname, ->(pathname) { where(pathname: pathname) }
  scope :for_name, ->(name) { where(name: name) }
  scope :ordered_by_hits, -> { order(hits: :desc) }
  scope :ordered_by_time, -> { order(time_bucket: :desc) }
  scope :older_than, ->(cutoff) { where(time_bucket: ...cutoff) }

  validates :name, :hostname, :pathname, :time_bucket, presence: true
end
