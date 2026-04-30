# frozen_string_literal: true

require "test_helper"

class SystemSettingTest < ActiveSupport::TestCase
  test "uniqueness constraint prevents duplicate name and value combination" do
    SystemSetting.create!(name: :allowed_registration_domain, value: "test-duplicate.com")
    duplicate = SystemSetting.new(name: :allowed_registration_domain, value: "test-duplicate.com")
    assert_not duplicate.valid?
    assert duplicate.errors[:value].any?
  end

  test "different values for the same name are allowed" do
    SystemSetting.create!(name: :allowed_registration_domain, value: "test-first.com")
    setting = SystemSetting.new(name: :allowed_registration_domain, value: "test-other.com")
    assert setting.valid?
  end
end
