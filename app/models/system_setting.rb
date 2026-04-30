# frozen_string_literal: true

# == Schema Information
#
# Table name: system_settings
# Database name: primary
#
#  id         :integer          not null, primary key
#  name       :integer          not null
#  value      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_system_settings_on_name_and_value  (name,value) UNIQUE
#
class SystemSetting < ApplicationRecord
  enum :name, { allowed_registration_domain: 0 }, validate: true

  validates :value, presence: true
  validates :value, uniqueness: { scope: :name }
end
