# frozen_string_literal: true

require "test_helper"

class Onboarding::SitesControllerTest < ActionDispatch::IntegrationTest
  test "redirects unauthenticated users to login for new action" do
    get new_onboarding_site_path

    assert_redirected_to login_path
  end

  test "redirects unauthenticated users to login for create action" do
    post onboarding_sites_path, params: { site: { name: "Test Site" } }

    assert_redirected_to login_path
  end

  test "redirects to sites_path if user already has sites" do
    login(users(:alice))

    get new_onboarding_site_path

    assert_redirected_to sites_path
  end

  test "authenticated users without sites can access new action" do
    user = User.create!(email: "newuser@example.com", password: "password12345", password_confirmation: "password12345")
    login(user, password: "password12345")

    get new_onboarding_site_path

    assert_response :success
  end

  test "redirects to sites_path on create if user already has sites" do
    login(users(:alice))

    post onboarding_sites_path, params: { site: { name: "Another Site" } }

    assert_redirected_to sites_path
  end

  test "valid site creation creates both Site and Membership as admin" do
    user = User.create!(email: "newuser@example.com", password: "password12345", password_confirmation: "password12345")
    login(user, password: "password12345")

    assert_difference("Site.count", 1) do
      assert_difference("Membership.count", 1) do
        post onboarding_sites_path, params: { site: { name: "My Test Site" } }
      end
    end

    site = Site.last
    assert_equal "My Test Site", site.name
    assert user.admin_for?(site)
  end

  test "valid site creation renders show page" do
    user = User.create!(email: "newuser@example.com", password: "password12345", password_confirmation: "password12345")
    login(user, password: "password12345")

    post onboarding_sites_path, params: { site: { name: "My Test Site" } }

    assert_response :success
    assert_select "h1", text: "Your Site is Ready!"
  end

  test "invalid site creation re-renders form with errors" do
    user = User.create!(email: "newuser@example.com", password: "password12345", password_confirmation: "password12345")
    login(user, password: "password12345")

    post onboarding_sites_path, params: { site: { name: "" } }

    assert_response :unprocessable_entity
    assert_select ".bg-danger-bg"
  end

  test "successful creation displays setup instructions" do
    user = User.create!(email: "newuser@example.com", password: "password12345", password_confirmation: "password12345")
    login(user, password: "password12345")

    post onboarding_sites_path, params: { site: { name: "My Test Site" } }

    assert_select 'div[data-controller="clipboard"]'
  end

  test "successful creation displays links to dashboard and settings" do
    user = User.create!(email: "newuser@example.com", password: "password12345", password_confirmation: "password12345")
    login(user, password: "password12345")

    post onboarding_sites_path, params: { site: { name: "My Test Site" } }

    site = Site.last
    assert_select "a[href='#{site_path(site)}']", text: "View Dashboard"
    assert_select "a[href='#{edit_site_path(site)}']", text: "Site Settings"
  end
end
