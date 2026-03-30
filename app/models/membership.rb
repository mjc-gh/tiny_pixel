# frozen_string_literal: true

# == Schema Information
#
# Table name: memberships
# Database name: primary
#
#  id         :integer          not null, primary key
#  role       :integer          default(0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  site_id    :integer          not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_memberships_on_site_id              (site_id)
#  index_memberships_on_user_id              (user_id)
#  index_memberships_on_user_id_and_site_id  (user_id,site_id) UNIQUE
#
# Foreign Keys
#
#  site_id  (site_id => sites.id)
#  user_id  (user_id => users.id)
#
class Membership < ApplicationRecord
  enum :role, { member: 0, admin: 1 }

  belongs_to :user
  belongs_to :site

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :site_id, message: "is already a member of this site" }
end
