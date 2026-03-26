# frozen_string_literal: true

# == Schema Information
#
# Table name: sites
# Database name: primary
#
#  id                      :integer          not null, primary key
#  name                    :string           not null
#  salt                    :string           not null
#  salt_duration           :integer          default("daily"), not null
#  salt_last_cycled_at     :datetime         not null
#  salt_version            :integer          default(0), not null
#  session_timeout_minutes :integer          default(30)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  property_id             :string           not null
#
# Indexes
#
#  index_sites_on_property_id  (property_id) UNIQUE
#
class Site < ApplicationRecord
  PROPERTY_ID_LENGHT = 8

  before_validation :set_property_id, on: :create
  before_create :cycle_salt

  # TODO handle :weekly (and maybe :monthly?)
  enum :salt_duration, [:daily]

  validates :name, :property_id, :salt, presence: true
  validates :name, length: { maximum: 60 }
  validates :session_timeout_minutes,
            presence: true,
            numericality: { greater_than_or_equal_to: 5, less_than_or_equal_to: 1440 }

  scope :need_to_cycle_salt, -> { where(salt_last_cycled_at: ..1.day.ago) }

  class << self
    def perform_periodic_operations
      # TODO: Aggregate new page visits data

      # Update site salt
      cycle_stale_salts!

      # TODO: remove visitors with older salt_version
    end

    private

    def cycle_stale_salts!
      need_to_cycle_salt.find_each do |site|
        site.cycle_salt
        site.save!
      end
    end
  end

  # TODO: check if salt should actually be cycled based upon salt duration and
  # last cycled timestamp
  def cycle_salt
    self.salt = SecureRandom.urlsafe_base64(32)
    self.salt_version += 1
    self.salt_last_cycled_at = Time.current
  end

  def session_timeout
    session_timeout_minutes.minutes
  end

  private

  def set_property_id
    charset = ("A".."Z").to_a

    self.property_id = String.new.tap do |prop_id|
      PROPERTY_ID_LENGHT.times { prop_id << charset[SecureRandom.rand(charset.size)] }
    end
  end
end
