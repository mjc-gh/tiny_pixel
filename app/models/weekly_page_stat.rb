# frozen_string_literal: true

class WeeklyPageStat < ApplicationRecord
  belongs_to :site

  scope :for_site, ->(site_id) { where(site_id: site_id) }
  scope :for_date_range, ->(start_date, end_date) { where(week_start: start_date..end_date) }
  scope :for_hostname, ->(hostname) { where(hostname: hostname) }
  scope :for_pathname, ->(pathname) { where(pathname: pathname) }
  scope :ordered_by_pageviews, -> { order(pageviews: :desc) }
  scope :ordered_by_week, -> { order(week_start: :desc) }

  validates :hostname, :pathname, :week_start, presence: true

  def avg_duration
    return nil if duration_count.zero?

    total_duration / duration_count
  end

  def bounce_rate
    return nil if pageviews.zero?

    (bounced_count.to_f / pageviews * 100).round(2)
  end
end
