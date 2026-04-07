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

  test "show redirects unauthenticated users to login" do
    get site_url(sites(:my_blog))

    assert_redirected_to login_path
  end

  test "authenticated users can access show" do
    login(users(:alice), password: "password123")

    get site_url(sites(:my_blog))

    assert_response :success
  end

  test "show displays site name" do
    login(users(:alice), password: "password123")

    get site_url(sites(:my_blog))

    assert_select "h1", text: sites(:my_blog).name
  end

  test "show displays turbo frames for stats sections" do
    login(users(:alice), password: "password123")

    get site_url(sites(:my_blog))

    assert_select "turbo-frame#page_views_stats"
    assert_select "turbo-frame#visitors_stats"
    assert_select "turbo-frame#avg_duration_stats"
    assert_select "turbo-frame#bounce_rate_stats"
  end

  test "show displays interval selector" do
    login(users(:alice), password: "password123")

    get site_url(sites(:my_blog))

    assert_select "select#interval"
  end

  test "show accepts interval parameter" do
    login(users(:alice), password: "password123")

    get site_url(sites(:my_blog), interval: "hourly")

    assert_response :success
  end

  test "show defaults to daily interval" do
    login(users(:alice), password: "password123")

    get site_url(sites(:my_blog))

    assert_select "option[value='#{site_path(sites(:my_blog), interval: 'daily')}'][selected]"
  end

  test "show returns 404 for unauthorized site" do
    login(users(:bob), password: "password123")

    get site_url(sites(:tech_blog))

    assert_response :not_found
  end

  test "show allows bob to access my_blog where he is a member" do
    login(users(:bob), password: "password123")

    get site_url(sites(:my_blog))

    assert_response :success
  end

  test "edit redirects unauthenticated users to login" do
    get edit_site_url(sites(:my_blog))

    assert_redirected_to login_path
  end

  test "authenticated users can access edit for their sites" do
    login(users(:alice), password: "password123")

    get edit_site_url(sites(:my_blog))

    assert_response :success
  end

  test "edit displays current site settings" do
    login(users(:alice), password: "password123")

    get edit_site_url(sites(:my_blog))

    assert_select "select#site_salt_duration"
    assert_select "input#site_display_hostname[type='checkbox']"
  end

  test "update redirects unauthenticated users to login" do
    patch site_url(sites(:my_blog)), params: { site: { salt_duration: "weekly" } }

    assert_redirected_to login_path
  end

  test "update saves valid salt_duration changes" do
    login(users(:alice), password: "password123")
    original_duration = sites(:my_blog).salt_duration

    patch site_url(sites(:my_blog)), params: { site: { salt_duration: "weekly" } }

    sites(:my_blog).reload
    assert_equal "weekly", sites(:my_blog).salt_duration
    assert_not_equal original_duration, sites(:my_blog).salt_duration
  end

  test "update saves valid display_hostname changes" do
    login(users(:alice), password: "password123")
    original_display_hostname = sites(:my_blog).display_hostname

    patch site_url(sites(:my_blog)), params: { site: { display_hostname: !original_display_hostname } }

    sites(:my_blog).reload
    assert_equal !original_display_hostname, sites(:my_blog).display_hostname
  end

  test "update returns 404 for unauthorized site" do
    login(users(:bob), password: "password123")

    patch site_url(sites(:tech_blog)), params: { site: { salt_duration: "monthly" } }

    assert_response :not_found
  end

  test "update redirects to site show page on success" do
    login(users(:alice), password: "password123")

    patch site_url(sites(:my_blog)), params: { site: { salt_duration: "monthly" } }

    assert_redirected_to site_url(sites(:my_blog))
  end
end
