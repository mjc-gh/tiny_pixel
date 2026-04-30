# frozen_string_literal: true

require "test_helper"

class Admin::SitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @site = sites(:my_blog)
  end

  test "index with auth headers is successful" do
    get admin_sites_path, headers: admin_auth_headers

    assert_response :success
    assert_select "h1", I18n.t("admin.sites.index.title")
  end

  test "index without auth headers is unauthorized" do
    get admin_sites_path

    assert_response :unauthorized
  end

  test "index displays all sites" do
    Site.create!(name: "Another Site")

    get admin_sites_path, headers: admin_auth_headers

    assert_response :success
    assert_select "tbody tr", count: Site.count
  end

  test "index displays property IDs" do
    get admin_sites_path, headers: admin_auth_headers

    assert_response :success
    assert_select "code", text: @site.property_id
  end

  test "new with auth headers is successful" do
    get new_admin_site_path, headers: admin_auth_headers

    assert_response :success
    assert_select "form"
    assert_select "[name=?]", "site[name]"
  end

  test "new without auth headers is unauthorized" do
    get new_admin_site_path

    assert_response :unauthorized
  end

  test "create with valid name succeeds" do
    assert_difference("Site.count") do
      post admin_sites_path, headers: admin_auth_headers, params: {
        site: { name: "New Test Site" }
      }
    end

    new_site = Site.find_by(name: "New Test Site")
    assert_not_nil new_site
    assert_not_nil new_site.property_id
    assert_redirected_to admin_site_path(new_site)
  end

  test "create without auth headers is unauthorized" do
    assert_no_difference("Site.count") do
      post admin_sites_path, params: {
        site: { name: "New Test Site" }
      }
    end

    assert_response :unauthorized
  end

  test "create with invalid name returns unprocessable_entity" do
    assert_no_difference("Site.count") do
      post admin_sites_path, headers: admin_auth_headers, params: {
        site: { name: "" }
      }
    end

    assert_response :unprocessable_entity
    assert_select "form"
  end

  test "create with name too long returns unprocessable_entity" do
    assert_no_difference("Site.count") do
      post admin_sites_path, headers: admin_auth_headers, params: {
        site: { name: "a" * 61 }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create does not create membership" do
    assert_no_difference("Membership.count") do
      post admin_sites_path, headers: admin_auth_headers, params: {
        site: { name: "New Test Site" }
      }
    end
  end

  test "show with auth headers displays site details" do
    get admin_site_path(@site), headers: admin_auth_headers

    assert_response :success
    assert_select "h1", I18n.t("admin.sites.show.title")
    assert_select "code", text: @site.property_id
  end

  test "show without auth headers is unauthorized" do
    get admin_site_path(@site)

    assert_response :unauthorized
  end

  test "show displays memberships" do
    user = User.create!(
      email: "member@example.com",
      password: "valid_password_12",
      password_confirmation: "valid_password_12"
    )
    @site.memberships.create!(user: user, role: :admin)

    get admin_site_path(@site), headers: admin_auth_headers

    assert_response :success
    assert_select "p", text: user.email
  end

  test "show displays property ID as read-only" do
    get admin_site_path(@site), headers: admin_auth_headers

    assert_response :success
    assert_select "code", text: @site.property_id
  end

  test "edit with auth headers displays site" do
    get edit_admin_site_path(@site), headers: admin_auth_headers

    assert_response :success
    assert_select "h1", I18n.t("admin.sites.edit.title")
    assert_select "[name=?]", "site[name]"
  end

  test "edit without auth headers is unauthorized" do
    get edit_admin_site_path(@site)

    assert_response :unauthorized
  end

  test "edit displays all configuration fields" do
    get edit_admin_site_path(@site), headers: admin_auth_headers

    assert_response :success
    assert_select "[name=?]", "site[name]"
    assert_select "[name=?]", "site[salt_duration]"
    assert_select "[name=?]", "site[display_hostname]"
    assert_select "[name=?]", "site[session_timeout_minutes]"
    assert_select "[name=?]", "site[stats_retention_duration]"
    assert_select "[name=?]", "site[stats_retention_unit]"
  end

  test "edit displays property ID as read-only" do
    get edit_admin_site_path(@site), headers: admin_auth_headers

    assert_response :success
    assert_select "p", text: @site.property_id
  end

  test "update with valid params succeeds" do
    patch admin_site_path(@site), headers: admin_auth_headers, params: {
      site: {
        name: "Updated Site Name",
        salt_duration: "weekly",
        session_timeout_minutes: 60
      }
    }

    @site.reload
    assert_equal "Updated Site Name", @site.name
    assert_equal "weekly", @site.salt_duration
    assert_equal 60, @site.session_timeout_minutes
    assert_redirected_to admin_site_path(@site)
  end

  test "update without auth headers is unauthorized" do
    patch admin_site_path(@site), params: {
      site: { name: "Updated Name" }
    }

    assert_response :unauthorized
    @site.reload
    assert_not_equal "Updated Name", @site.name
  end

  test "update with invalid name returns unprocessable_entity" do
    patch admin_site_path(@site), headers: admin_auth_headers, params: {
      site: { name: "" }
    }

    assert_response :unprocessable_entity
    @site.reload
    assert_not_equal "", @site.name
  end

  test "update with invalid session_timeout_minutes returns unprocessable_entity" do
    patch admin_site_path(@site), headers: admin_auth_headers, params: {
      site: { session_timeout_minutes: 2 }
    }

    assert_response :unprocessable_entity
  end

  test "update all site settings" do
    patch admin_site_path(@site), headers: admin_auth_headers, params: {
      site: {
        name: "Complete Update",
        salt_duration: "monthly",
        display_hostname: true,
        session_timeout_minutes: 120,
        stats_retention_duration: 6,
        stats_retention_unit: "months"
      }
    }

    @site.reload
    assert_equal "Complete Update", @site.name
    assert_equal "monthly", @site.salt_duration
    assert @site.display_hostname
    assert_equal 120, @site.session_timeout_minutes
    assert_equal 6, @site.stats_retention_duration
    assert_equal "months", @site.stats_retention_unit
  end

  test "destroy with auth headers deletes site" do
    site_to_delete = Site.create!(name: "Site to Delete")

    assert_difference("Site.count", -1) do
      delete admin_site_path(site_to_delete), headers: admin_auth_headers
    end

    assert_redirected_to admin_sites_path
  end

  test "destroy without auth headers is unauthorized" do
    site_to_delete = Site.create!(name: "Site to Delete")

    assert_no_difference("Site.count") do
      delete admin_site_path(site_to_delete)
    end

    assert_response :unauthorized
  end

  test "destroy with auth headers deletes site memberships" do
    site_to_delete = Site.create!(name: "Site with Members")
    user = User.create!(
      email: "member@example.com",
      password: "valid_password_12",
      password_confirmation: "valid_password_12"
    )
    site_to_delete.memberships.create!(user: user, role: :admin)

    assert_difference("Membership.count", -1) do
      delete admin_site_path(site_to_delete), headers: admin_auth_headers
    end

    assert_redirected_to admin_sites_path
  end

  test "destroy redirects to index with success notice" do
    site_to_delete = Site.create!(name: "Site to Delete")

    delete admin_site_path(site_to_delete), headers: admin_auth_headers

    assert_redirected_to admin_sites_path
    assert_equal I18n.t("admin.sites.destroy.success"), flash[:notice]
  end

  test "create redirects to show with success notice" do
    post admin_sites_path, headers: admin_auth_headers, params: {
      site: { name: "New Test Site" }
    }

    new_site = Site.find_by(name: "New Test Site")
    assert_redirected_to admin_site_path(new_site)
    assert_equal I18n.t("admin.sites.create.success"), flash[:notice]
  end

  test "update redirects to show with success notice" do
    patch admin_site_path(@site), headers: admin_auth_headers, params: {
      site: { name: "Updated Site" }
    }

    assert_redirected_to admin_site_path(@site)
    assert_equal I18n.t("admin.sites.update.success"), flash[:notice]
  end
end
