# frozen_string_literal: true

# == Schema Information
#
# Table name: users
# Database name: primary
#
#  id                      :integer          not null, primary key
#  confirmed_at            :datetime
#  email                   :string           not null
#  invitation_code         :string
#  password_digest         :string           not null
#  password_reset_required :boolean          default(FALSE), not null
#  unconfirmed_email       :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes
#
#  index_users_on_email  (email) UNIQUE
#
class User < ApplicationRecord
  EmailDeliveryNotSupportedError = Class.new(StandardError)

  include ReviseAuth::Model
  prepend UserReviseExtension

  generates_token_for :invitation_code, expires_in: 7.days

  has_many :memberships, dependent: :destroy
  has_many :sites, through: :memberships

  def self.invite(email)
    raise EmailDeliveryNotSupportedError unless TinyPixel.email_delivery_supported?

    temp_password = SecureRandom.urlsafe_base64(ReviseAuth.minimum_password_length)
    user = create!(
      email: email,
      password: temp_password,
      password_confirmation: temp_password,
      password_reset_required: true
    )

    UserMailer.invitation(user).deliver_later

    user
  end

  def admin_for?(site)
    memberships.exists?(site: site, role: :admin)
  end

  def member_of?(site)
    memberships.exists?(site: site)
  end
end
