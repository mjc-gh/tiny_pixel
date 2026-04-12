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
end
