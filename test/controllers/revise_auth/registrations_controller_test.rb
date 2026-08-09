# frozen_string_literal: true

require "test_helper"

class ReviseAuth::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "authenticated profile exposes API Keys management" do
    login(users(:alice))

    get profile_url

    assert_select "a[href='#{api_keys_path}']", text: I18n.t("revise_auth.registrations.edit.manage_api_keys")
  end

  test "profile requires authentication" do
    get profile_url

    assert_redirected_to login_path
  end
end
