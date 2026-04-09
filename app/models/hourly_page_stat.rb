# frozen_string_literal: true

# == Schema Information
#
# Table name: hourly_page_stats
# Database name: primary
#
#  id               :integer          not null, primary key
#  bounced_count    :integer          default(0), not null
#  dimension        :string           default("global"), not null
#  duration_count   :integer          default(0), not null
#  hostname         :string           not null
#  pageviews        :integer          default(0), not null
#  pathname         :string           not null
#  sessions         :integer          default(0), not null
#  time_bucket      :datetime         not null
#  total_duration   :decimal(12, 2)   default(0.0), not null
#  unique_pageviews :integer          default(0), not null
#  visits           :integer          default(0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  site_id          :integer          not null
#
# Indexes
#
#  idx_hourly_page_stats_dimension       (dimension)
#  idx_hourly_page_stats_site_host_time  (site_id,hostname,time_bucket)
#  idx_hourly_page_stats_site_time       (site_id,time_bucket)
#  idx_hourly_page_stats_unique          (site_id,hostname,pathname,dimension,time_bucket) UNIQUE
#  index_hourly_page_stats_on_site_id    (site_id)
#
# Foreign Keys
#
#  site_id  (site_id => sites.id)
#
class HourlyPageStat < ApplicationRecord
  belongs_to :site

  scope :for_site, ->(site_id) { where(site_id: site_id) }
  scope :for_date_range, ->(start_time, end_time) { where(time_bucket: start_time..end_time) }
  scope :for_hostname, ->(hostname) { where(hostname: hostname) }
  scope :for_pathname, ->(pathname) { where(pathname: pathname) }
  scope :global, -> { where(dimension: "global") }
  scope :for_dimension, ->(dimension) { where(dimension: dimension) }
  scope :for_dimension_type, ->(type) { where("dimension LIKE ?", "#{type}:%") }
  scope :ordered_by_pageviews, -> { order(pageviews: :desc) }
  scope :ordered_by_time, -> { order(time_bucket: :desc) }

  validates :hostname, :pathname, :time_bucket, :dimension, presence: true

  def avg_duration
    return nil if duration_count.zero?

    total_duration / duration_count
  end

  def bounce_rate
    return nil if pageviews.zero?

    (bounced_count.to_f / pageviews * 100).round(2)
  end
end
