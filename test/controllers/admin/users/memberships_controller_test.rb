# frozen_string_literal: true

require "test_helper"

class Admin::Users::MembershipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    @site = Site.create!(name: "Test Site")
  end

  test "new with auth headers displays form" do
    get new_admin_user_membership_path(@user), headers: admin_auth_headers

    assert_response :success
    assert_select "h1", I18n.t("admin.users.memberships.new.title")
  end

  test "new without auth headers is unauthorized" do
    get new_admin_user_membership_path(@user)

    assert_response :unauthorized
  end

  test "new excludes sites user is already member of" do
    @user.memberships.create!(site: @site, role: :member)
    new_site = Site.create!(name: "Another Site")

    get new_admin_user_membership_path(@user), headers: admin_auth_headers

    assert_response :success
    assert_select "option", text: new_site.name
    assert_select "option", text: @site.name, count: 0
  end

  test "create with valid params creates membership" do
    assert_difference("Membership.count") do
      post admin_user_memberships_path(@user), headers: admin_auth_headers, params: {
        membership: { site_id: @site.id, role: "member" }
      }
    end

    membership = @user.memberships.last
    assert_equal @site.id, membership.site_id
    assert_equal "member", membership.role
    assert_redirected_to admin_user_path(@user)
  end

  test "create with admin role creates admin membership" do
    assert_difference("Membership.count") do
      post admin_user_memberships_path(@user), headers: admin_auth_headers, params: {
        membership: { site_id: @site.id, role: "admin" }
      }
    end

    membership = @user.memberships.last
    assert_equal "admin", membership.role
  end

  test "create without auth headers is unauthorized" do
    assert_no_difference("Membership.count") do
      post admin_user_memberships_path(@user), params: {
        membership: { site_id: @site.id, role: "member" }
      }
    end

    assert_response :unauthorized
  end

  test "create with duplicate membership returns unprocessable_entity" do
    @user.memberships.create!(site: @site, role: :member)

    assert_no_difference("Membership.count") do
      post admin_user_memberships_path(@user), headers: admin_auth_headers, params: {
        membership: { site_id: @site.id, role: "member" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create without site_id returns unprocessable_entity" do
    assert_no_difference("Membership.count") do
      post admin_user_memberships_path(@user), headers: admin_auth_headers, params: {
        membership: { role: "member" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "destroy with auth headers deletes membership" do
    membership = @user.memberships.create!(site: @site, role: :member)

    assert_difference("Membership.count", -1) do
      delete admin_user_membership_path(@user, membership), headers: admin_auth_headers
    end

    assert_redirected_to admin_user_path(@user)
  end

  test "destroy without auth headers is unauthorized" do
    membership = @user.memberships.create!(site: @site, role: :member)

    assert_no_difference("Membership.count") do
      delete admin_user_membership_path(@user, membership)
    end

    assert_response :unauthorized
  end
end
