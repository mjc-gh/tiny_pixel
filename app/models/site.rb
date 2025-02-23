# frozen_string_literal: true

class Site < ApplicationRecord
  before_create :cycle_salt

  enum :salt_duration, [:daily, :weekly]

  # TODO: check if salt should actually be cycled based upon salt duration and
  # last cycled timestamp
  def cycle_salt
    self.salt = SecureRandom.urlsafe_base64(32)
    self.salt_last_cycled_at = Time.current
  end
end
