# frozen_string_literal: true

require "test_helper"

class SitesControllerTest < ActionDispatch::IntegrationTest
  test "redirects unauthenticated users to login" do
    get sites_url

    assert_redirected_to login_path
  end

  test "authenticated users can access index" do
    login(users(:alice), password: "password123")

    get sites_url

    assert_response :success
  end

  test "displays user sites" do
    login(users(:alice), password: "password123")

    get sites_url

    assert_select "h2", text: sites(:my_blog).name
    assert_select "h2", text: sites(:tech_blog).name
  end

  test "does not display other users sites" do
    login(users(:bob), password: "password123")

    get sites_url

    assert_select "h2", text: sites(:my_blog).name
    assert_select "h2", text: sites(:tech_blog).name, count: 0
  end

  test "shows empty state when user has no sites" do
    user = User.create!(email: "newuser@example.com", password: "password12345", password_confirmation: "password12345")
    login(user, password: "password12345")

    get sites_url

    assert_select "p", text: "You don't have any sites yet."
  end
end
