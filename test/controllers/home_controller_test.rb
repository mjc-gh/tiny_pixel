# frozen_string_literal: true

require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "redirects to sites index when user is logged in" do
    user = users(:alice)
    login(user)
    get root_url
    assert_redirected_to sites_path
  end

  test "renders home page when user is not logged in" do
    get root_url
    assert_response :success
  end

  test "renders setup instructions in cold start state (no users)" do
    # Mock User.none? to return true for cold start simulation
    User.stub :none?, true do
      get root_url
      assert_response :success
      assert_select "h1", text: I18n.t("home.setup.title")
      assert_select "h2", text: I18n.t("home.setup.step_1_title")
      assert_select "h2", text: I18n.t("home.setup.step_2_title")
      assert_select "h2", text: I18n.t("home.setup.step_3_title")
      assert_select "code", text: "./bin/rails tiny_pixel:system_admin_password"
    end
  end

  test "does not render setup instructions when users exist" do
    get root_url
    assert_response :success
    # Check that the setup title is NOT present when users exist
    assert_select "h1", text: I18n.t("home.setup.title"), count: 0
  end
end
