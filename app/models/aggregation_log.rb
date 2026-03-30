# frozen_string_literal: true

# == Schema Information
#
# Table name: aggregation_logs
# Database name: primary
#
#  id               :integer          not null, primary key
#  aggregation_type :string           not null
#  completed_at     :datetime
#  rows_created     :integer          default(0), not null
#  rows_updated     :integer          default(0), not null
#  time_bucket      :datetime         not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  site_id          :integer          not null
#
# Indexes
#
#  idx_aggregation_logs_site_type_time  (site_id,aggregation_type,time_bucket)
#  index_aggregation_logs_on_site_id    (site_id)
#
# Foreign Keys
#
#  site_id  (site_id => sites.id)
#
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
