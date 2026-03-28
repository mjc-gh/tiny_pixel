# frozen_string_literal: true

class AggregationLog < ApplicationRecord
  AGGREGATION_TYPES = %w[hourly daily weekly].freeze

  belongs_to :site

  scope :for_site, ->(site_id) { where(site_id: site_id) }
  scope :for_type, ->(type) { where(aggregation_type: type) }
  scope :recent, -> { order(time_bucket: :desc) }
  scope :completed, -> { where.not(completed_at: nil) }

  validates :aggregation_type, presence: true, inclusion: { in: AGGREGATION_TYPES }
  validates :time_bucket, presence: true

  def completed?
    completed_at.present?
  end

  def mark_completed!(rows_created: 0, rows_updated: 0)
    update!(
      completed_at: Time.current,
      rows_created: rows_created,
      rows_updated: rows_updated
    )
  end
end
