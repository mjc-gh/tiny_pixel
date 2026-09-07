# frozen_string_literal: true

# == Schema Information
#
# Table name: daily_event_stats
# Database name: primary
#
#  id          :integer          not null, primary key
#  date        :date             not null
#  hits        :integer          default(0), not null
#  hostname    :string           not null
#  name        :string           not null
#  pathname    :string           not null
#  unique_hits :integer          default(0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  site_id     :integer          not null
#
# Indexes
#
#  idx_daily_event_stats_site_host_time  (site_id,hostname,date)
#  idx_daily_event_stats_site_name_time  (site_id,name,date)
#  idx_daily_event_stats_site_time       (site_id,date)
#  idx_daily_event_stats_unique          (site_id,name,hostname,pathname,date) UNIQUE
#  index_daily_event_stats_on_site_id    (site_id)
#
# Foreign Keys
#
#  site_id  (site_id => sites.id)
#
class DailyEventStat < ApplicationRecord
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
    where(date: range) if range
  }
  scope :for_hostname, ->(hostname) { where(hostname: hostname) }
  scope :for_pathname, ->(pathname) { where(pathname: pathname) }
  scope :for_name, ->(name) { where(name: name) }
  scope :ordered_by_hits, -> { order(hits: :desc) }
  scope :ordered_by_date, -> { order(date: :desc) }
  scope :older_than, ->(cutoff) { where(date: ...cutoff.to_date) }

  validates :name, :hostname, :pathname, :date, presence: true
end
