# frozen_string_literal: true

require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "get index" do
    get admin_url, headers: admin_auth_headers

    assert_response :success
  end

  test "get index without basic auth is unauthorized" do
    get admin_url

    assert_response :unauthorized
  end
end
