# frozen_string_literal: true

require "test_helper"

class Admin::SystemSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    SystemSetting.where(name: :allowed_registration_domain).delete_all
  end

  test "show with auth headers is successful" do
    get admin_system_settings_path, headers: admin_auth_headers

    assert_response :success
    assert_select "h1", I18n.t("admin.system_settings.show.title")
  end

  test "show without auth headers is unauthorized" do
    get admin_system_settings_path

    assert_response :unauthorized
  end

  test "show displays allowed registration domains" do
    SystemSetting.create!(name: :allowed_registration_domain, value: "example.com")
    SystemSetting.create!(name: :allowed_registration_domain, value: "test.com")

    get admin_system_settings_path, headers: admin_auth_headers

    assert_response :success
    assert_select "textarea[name=?]", "domains" do
      assert_match(/example\.com/, response.body)
      assert_match(/test\.com/, response.body)
    end
  end

  test "show with no domains displays empty textarea" do
    get admin_system_settings_path, headers: admin_auth_headers

    assert_response :success
    assert_select "textarea[name=?]", "domains"
  end
end
