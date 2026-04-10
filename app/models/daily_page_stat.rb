# frozen_string_literal: true

# == Schema Information
#
# Table name: daily_page_stats
# Database name: primary
#
#  id               :integer          not null, primary key
#  bounced_count    :integer          default(0), not null
#  date             :date             not null
#  dimension_type   :string           default("global"), not null
#  dimension_value  :string
#  duration_count   :integer          default(0), not null
#  hostname         :string           not null
#  pageviews        :integer          default(0), not null
#  pathname         :string           not null
#  sessions         :integer          default(0), not null
#  total_duration   :decimal(12, 2)   default(0.0), not null
#  unique_pageviews :integer          default(0), not null
#  visits           :integer          default(0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  site_id          :integer          not null
#
# Indexes
#
#  idx_daily_page_stats_dimension_type  (dimension_type)
#  idx_daily_page_stats_site_date       (site_id,date)
#  idx_daily_page_stats_site_host_date  (site_id,hostname,date)
#  idx_daily_page_stats_unique          (site_id,hostname,pathname,dimension_type,dimension_value,date) UNIQUE
#  index_daily_page_stats_on_site_id    (site_id)
#
# Foreign Keys
#
#  site_id  (site_id => sites.id)
#
class DailyPageStat < ApplicationRecord
  belongs_to :site

  scope :for_site, ->(site_id) { where(site_id: site_id) }
  scope :for_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :for_hostname, ->(hostname) { where(hostname: hostname) }
  scope :for_pathname, ->(pathname) { where(pathname: pathname) }
  scope :global, -> { where(dimension_type: "global") }
  scope :for_dimension, ->(type, value) { where(dimension_type: type, dimension_value: value) }
  scope :for_dimension_type, ->(type) { where(dimension_type: type) }
  scope :ordered_by_pageviews, -> { order(pageviews: :desc) }
  scope :ordered_by_date, -> { order(date: :desc) }

  validates :hostname, :pathname, :date, :dimension_type, presence: true

  def avg_duration
    return nil if duration_count.zero?

    total_duration / duration_count
  end

  def bounce_rate
    return nil if pageviews.zero?

    (bounced_count.to_f / pageviews * 100).round(2)
  end
end
