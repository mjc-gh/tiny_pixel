# frozen_string_literal: true

require "test_helper"

module Sites
  class MembershipsControllerTest < ActionDispatch::IntegrationTest
    # Index action tests
    test "index redirects unauthenticated users to login" do
      get site_memberships_url(sites(:my_blog))

      assert_redirected_to login_path
    end

    test "index returns 404 for non-members" do
      # Create a new user who is not a member of tech_blog
      user = User.create!(email: "newuser@example.com", password: "password123456789", password_confirmation: "password123456789", confirmed_at: Time.current)
      login(user, password: "password123456789")

      get site_memberships_url(sites(:tech_blog))

      assert_response :not_found
    end

    test "index returns 403 for members with member role" do
      login(users(:bob))

      get site_memberships_url(sites(:my_blog))

      assert_response :forbidden
    end

    test "index allows admins to view all memberships" do
      login(users(:alice))

      get site_memberships_url(sites(:my_blog))

      assert_response :success
    end

    test "index displays all site memberships" do
      login(users(:alice))

      get site_memberships_url(sites(:my_blog))

      assert_select "table"
      assert_includes response.body, users(:alice).email
      assert_includes response.body, users(:bob).email
      assert_includes response.body, users(:charlie).email
    end

    test "index displays member roles" do
      login(users(:alice))

      get site_memberships_url(sites(:my_blog))

      assert_includes response.body, I18n.t("sites.memberships.roles.admin")
      assert_includes response.body, I18n.t("sites.memberships.roles.member")
    end

    test "index shows page title" do
      login(users(:alice))

      get site_memberships_url(sites(:my_blog))

      assert_includes response.body, I18n.t("sites.memberships.index.title")
    end

    test "index hides remove button for current user" do
      login(users(:alice))

      get site_memberships_url(sites(:my_blog))

      # Count the number of delete links
      delete_links = response.body.scan(/data-method="delete"/).count
      # Should be 2: one for bob, one for charlie (not for alice)
      assert_equal 2, delete_links
    end

    # Edit action tests
    test "edit redirects unauthenticated users to login" do
      get edit_site_membership_url(sites(:my_blog), memberships(:alice_my_blog_admin))

      assert_redirected_to login_path
    end

    test "edit returns 404 for non-members" do
      # Create a new user who is not a member of tech_blog
      user = User.create!(email: "newuser@example.com", password: "password123456789", password_confirmation: "password123456789", confirmed_at: Time.current)
      login(user, password: "password123456789")

      get edit_site_membership_url(sites(:tech_blog), memberships(:alice_tech_blog_admin))

      assert_response :not_found
    end

    test "edit returns 403 for members with member role" do
      login(users(:bob))

      get edit_site_membership_url(sites(:my_blog), memberships(:charlie_my_blog_member))

      assert_response :forbidden
    end

    test "edit allows admins to view edit form" do
      login(users(:alice))

      get edit_site_membership_url(sites(:my_blog), memberships(:bob_my_blog_member))

      assert_response :success
    end

    test "edit shows role options" do
      login(users(:alice))

      get edit_site_membership_url(sites(:my_blog), memberships(:bob_my_blog_member))

      assert_includes response.body, I18n.t("sites.memberships.roles.member")
      assert_includes response.body, I18n.t("sites.memberships.roles.admin")
    end

    test "edit shows warning for self-demotion attempt" do
      login(users(:alice))

      get edit_site_membership_url(sites(:my_blog), memberships(:alice_my_blog_admin))

      assert_includes response.body, I18n.t("sites.memberships.update.cannot_demote_self")
    end

    test "edit disables role dropdown for self when admin" do
      login(users(:alice))

      get edit_site_membership_url(sites(:my_blog), memberships(:alice_my_blog_admin))

      assert_select "select[disabled]"
    end

    # Update action tests
    test "update redirects unauthenticated users to login" do
      patch site_membership_url(sites(:my_blog), memberships(:bob_my_blog_member)), params: { membership: { role: "admin" } }

      assert_redirected_to login_path
    end

    test "update returns 404 for non-members" do
      # Create a new user who is not a member of tech_blog
      user = User.create!(email: "newuser@example.com", password: "password123456789", password_confirmation: "password123456789", confirmed_at: Time.current)
      login(user, password: "password123456789")

      patch site_membership_url(sites(:tech_blog), memberships(:alice_tech_blog_admin)), params: { membership: { role: "member" } }

      assert_response :not_found
    end

    test "update returns 403 for members with member role" do
      login(users(:bob))

      patch site_membership_url(sites(:my_blog), memberships(:charlie_my_blog_member)), params: { membership: { role: "admin" } }

      assert_response :forbidden
    end

    test "update allows admins to change another member's role" do
      login(users(:alice))

      patch site_membership_url(sites(:my_blog), memberships(:bob_my_blog_member)), params: { membership: { role: "admin" } }

      assert_redirected_to site_memberships_url(sites(:my_blog))
      assert_equal "admin", memberships(:bob_my_blog_member).reload.role
    end

    test "update shows success flash when role changed" do
      login(users(:alice))

      patch site_membership_url(sites(:my_blog), memberships(:bob_my_blog_member)), params: { membership: { role: "admin" } }

      assert_equal I18n.t("sites.memberships.update.success"), flash[:notice]
    end

    test "update prevents admin from demoting themselves" do
      login(users(:alice))

      patch site_membership_url(sites(:my_blog), memberships(:alice_my_blog_admin)), params: { membership: { role: "member" } }

      assert_response :unprocessable_entity
      assert_equal "admin", memberships(:alice_my_blog_admin).reload.role
      assert_includes response.body, I18n.t("sites.memberships.update.cannot_demote_self")
    end

    # Destroy action tests
    test "destroy redirects unauthenticated users to login" do
      delete site_membership_url(sites(:my_blog), memberships(:bob_my_blog_member))

      assert_redirected_to login_path
    end

    test "destroy returns 404 for non-members" do
      # Create a new user who is not a member of tech_blog
      user = User.create!(email: "newuser@example.com", password: "password123456789", password_confirmation: "password123456789", confirmed_at: Time.current)
      login(user, password: "password123456789")

      delete site_membership_url(sites(:tech_blog), memberships(:alice_tech_blog_admin))

      assert_response :not_found
    end

    test "destroy returns 403 for members with member role" do
      login(users(:bob))

      delete site_membership_url(sites(:my_blog), memberships(:charlie_my_blog_member))

      assert_response :forbidden
    end

    test "destroy allows admins to remove another member" do
      login(users(:alice))

      delete site_membership_url(sites(:my_blog), memberships(:bob_my_blog_member))

      assert_redirected_to site_memberships_url(sites(:my_blog))
      assert_not Membership.exists?(memberships(:bob_my_blog_member).id)
    end

    test "destroy shows success flash when member removed" do
      login(users(:alice))

      delete site_membership_url(sites(:my_blog), memberships(:bob_my_blog_member))

      assert_equal I18n.t("sites.memberships.destroy.success"), flash[:notice]
    end

    test "destroy prevents admin from removing themselves" do
      login(users(:alice))

      delete site_membership_url(sites(:my_blog), memberships(:alice_my_blog_admin))

      assert_redirected_to site_memberships_url(sites(:my_blog))
      assert Membership.exists?(memberships(:alice_my_blog_admin).id)
      assert_equal I18n.t("sites.memberships.destroy.cannot_remove_self"), flash[:alert]
    end

    test "destroy prevents member from removing themselves" do
      login(users(:bob))
      bob_membership = memberships(:bob_my_blog_member)

      delete site_membership_url(sites(:my_blog), bob_membership)

      # First it returns forbidden because bob is not an admin
      assert_response :forbidden
      assert Membership.exists?(bob_membership.id)
    end
  end
end
