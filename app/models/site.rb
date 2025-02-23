# frozen_string_literal: true

class Site < ApplicationRecord
  PROPERTY_ID_LENGHT = 8

  before_validation :set_property_id, on: :create
  before_create :cycle_salt

  # TODO handle :weekly (and maybe :monthly?)
  enum :salt_duration, [:daily]

  validates :name, :property_id, :salt, presence: true
  validates :name, length: { maximum: 60 }

  scope :need_to_cycle_salt, -> { where(salt_last_cycled_at: ..1.day.ago) }

  class << self
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
    self.salt_last_cycled_at = Time.current
  end

  private

  def set_property_id
    charset = ("A".."Z").to_a

    self.property_id = String.new.tap do |prop_id|
      PROPERTY_ID_LENGHT.times { prop_id << charset[SecureRandom.rand(charset.size)] }
    end
  end
end
