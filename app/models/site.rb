# frozen_string_literal: true

# == Schema Information
#
# Table name: sites
# Database name: primary
#
#  id                       :integer          not null, primary key
#  display_hostname         :boolean          default(FALSE), not null
#  name                     :string           not null
#  salt                     :string           not null
#  salt_duration            :integer          default("daily"), not null
#  salt_last_cycled_at      :datetime         not null
#  salt_version             :integer          default(0), not null
#  session_timeout_minutes  :integer          default(30)
#  stats_retention_duration :integer          default(12), not null
#  stats_retention_unit     :integer          default("months"), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  property_id              :string           not null
#
# Indexes
#
#  index_sites_on_property_id  (property_id) UNIQUE
#
class Site < ApplicationRecord
  PROPERTY_ID_LENGHT = 8

  before_validation :set_property_id, on: :create
  before_validation :cycle_salt, on: :create

  enum :salt_duration, { daily: 0, weekly: 1, monthly: 2 }
  enum :stats_retention_unit, { days: 0, weeks: 1, months: 2, years: 3 }

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :hourly_page_stats, dependent: :destroy
  has_many :daily_page_stats, dependent: :destroy
  has_many :weekly_page_stats, dependent: :destroy
  has_many :aggregation_logs, dependent: :destroy

  validates :name, :property_id, :salt, presence: true
  validates :name, length: { maximum: 60 }
  validates :stats_retention_duration, numericality: { greater_than: 0 }
  validates :session_timeout_minutes,
            presence: true,
            numericality: { greater_than_or_equal_to: 5, less_than_or_equal_to: 1440 }

  scope :need_to_cycle_salt, lambda {
    daily_cutoff = 1.day.ago
    weekly_cutoff = 1.week.ago
    monthly_cutoff = 1.month.ago

    where(salt_duration: :daily, salt_last_cycled_at: ..daily_cutoff)
      .or(where(salt_duration: :weekly, salt_last_cycled_at: ..weekly_cutoff))
      .or(where(salt_duration: :monthly, salt_last_cycled_at: ..monthly_cutoff))
  }

  class << self
    def cycle_stale_salts!
      need_to_cycle_salt.find_each do |site|
        stale_salt_version = site.salt_version
        site.cycle_salt
        site.save!

        # Destroy stale visitors and their page views
        Visitor.where(property_id: site.id)
               .where(salt_version: ...stale_salt_version)
               .destroy_all
      end
    end
  end

  def cycle_salt
    self.salt = SecureRandom.urlsafe_base64(32)
    self.salt_version += 1
    self.salt_last_cycled_at = Time.current
  end

  def session_timeout
    session_timeout_minutes.minutes
  end

  def stats_retention_period
    stats_retention_duration.send(stats_retention_unit)
  end

  def stats_retention_cutoff
    stats_retention_period.ago
  end

  def age_in_days
    ((Time.current - created_at) / 1.day).floor
  end

  private

  def set_property_id
    charset = ("A".."Z").to_a

    self.property_id = String.new.tap do |prop_id|
      PROPERTY_ID_LENGHT.times { prop_id << charset[SecureRandom.rand(charset.size)] }
    end
  end
end
