# frozen_string_literal: true

require "test_helper"

class Admin::SystemSettings::AllowedRegistrationDomainsControllerTest < ActionDispatch::IntegrationTest
  setup do
    SystemSetting.where(name: :allowed_registration_domain).delete_all
  end

  test "update with auth headers is successful" do
    patch admin_system_settings_allowed_registration_domains_path,
          params: { domains: "example.com\ntest.com" },
          headers: admin_auth_headers

    assert_response :redirect
    assert_redirected_to admin_system_settings_path
  end

  test "update without auth headers is unauthorized" do
    patch admin_system_settings_allowed_registration_domains_path,
          params: { domains: "example.com" }

    assert_response :unauthorized
  end

  test "update with valid domains creates records" do
    patch admin_system_settings_allowed_registration_domains_path,
          params: { domains: "example.com\ntest.com" },
          headers: admin_auth_headers

    assert_response :redirect
    assert_equal 2, SystemSetting.where(name: :allowed_registration_domain).count
    assert SystemSetting.exists?(name: :allowed_registration_domain, value: "example.com")
    assert SystemSetting.exists?(name: :allowed_registration_domain, value: "test.com")
  end

  test "update with empty submission deletes all records" do
    SystemSetting.create!(name: :allowed_registration_domain, value: "example.com")
    SystemSetting.create!(name: :allowed_registration_domain, value: "test.com")

    patch admin_system_settings_allowed_registration_domains_path,
          params: { domains: "" },
          headers: admin_auth_headers

    assert_response :redirect
    assert_equal 0, SystemSetting.where(name: :allowed_registration_domain).count
  end

  test "update replaces existing domains with new ones" do
    SystemSetting.create!(name: :allowed_registration_domain, value: "old.com")

    patch admin_system_settings_allowed_registration_domains_path,
          params: { domains: "new.com\nanother.com" },
          headers: admin_auth_headers

    assert_response :redirect
    assert_equal 2, SystemSetting.where(name: :allowed_registration_domain).count
    assert SystemSetting.exists?(name: :allowed_registration_domain, value: "new.com")
    assert SystemSetting.exists?(name: :allowed_registration_domain, value: "another.com")
    assert_not SystemSetting.exists?(name: :allowed_registration_domain, value: "old.com")
  end

  test "update handles whitespace and blank lines correctly" do
    patch admin_system_settings_allowed_registration_domains_path,
          params: { domains: "  example.com  \n\n  test.com  \n" },
          headers: admin_auth_headers

    assert_response :redirect
    assert_equal 2, SystemSetting.where(name: :allowed_registration_domain).count
    assert SystemSetting.exists?(name: :allowed_registration_domain, value: "example.com")
    assert SystemSetting.exists?(name: :allowed_registration_domain, value: "test.com")
  end

  test "update redirects with success notice" do
    patch admin_system_settings_allowed_registration_domains_path,
          params: { domains: "example.com" },
          headers: admin_auth_headers

    assert_response :redirect
    follow_redirect! headers: admin_auth_headers
    assert_response :success
    assert_select "#flash-success" do
      assert_match(I18n.t("admin.system_settings.allowed_registration_domains.update.success"), response.body)
    end
  end
end
