# frozen_string_literal: true

# == Schema Information
#
# Table name: api_keys
# Database name: primary
#
#  id           :integer          not null, primary key
#  expires_at   :datetime
#  name         :string           not null
#  token_digest :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :integer          not null
#
# Indexes
#
#  index_api_keys_on_token_digest  (token_digest) UNIQUE
#  index_api_keys_on_user_id       (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class ApiKey < ApplicationRecord
  belongs_to :user

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }

  validates :name, presence: true, length: { maximum: 100 }
  validates :token_digest, presence: true
  validate :expires_at_in_the_future

  before_validation :generate_token, on: :create

  attr_reader :token

  def self.authenticate(token)
    return if token.blank?

    api_key = find_by(token_digest: Digest::SHA256.hexdigest(token))
    api_key if api_key&.active?
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def active?
    !expired?
  end

  private

  def generate_token
    return if token.present?

    @token = "tiny_pixel_#{SecureRandom.urlsafe_base64(32, false)}"
    self.token_digest = Digest::SHA256.hexdigest(token)
  end

  def expires_at_in_the_future
    return if expires_at.blank? || expires_at > Time.current

    errors.add(:expires_at, :in_the_future)
  end
end
