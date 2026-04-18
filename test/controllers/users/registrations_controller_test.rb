require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "redirects to login when registration is not allowed" do
    get sign_up_path
    assert_redirected_to login_url
    assert_equal I18n.t("users.registrations.not_allowed"), flash[:alert]
  end

  test "renders registration form when registration is allowed" do
    Rails.application.config.runtime_settings.allow_registration = true
    get sign_up_path
    assert_response :success
    assert_select "form"
  ensure
    Rails.application.config.runtime_settings.allow_registration = false
  end
end
