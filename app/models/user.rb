# frozen_string_literal: true

# == Schema Information
#
# Table name: users
# Database name: primary
#
#  id                :integer          not null, primary key
#  confirmed_at      :datetime
#  email             :string           not null
#  password_digest   :string           not null
#  unconfirmed_email :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_users_on_email  (email) UNIQUE
#
class User < ApplicationRecord
  include ReviseAuth::Model

  has_many :memberships, dependent: :destroy
  has_many :sites, through: :memberships

  def admin_for?(site)
    memberships.exists?(site: site, role: :admin)
  end

  def member_of?(site)
    memberships.exists?(site: site)
  end
end
