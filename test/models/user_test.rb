# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "admin_for? returns true when user is admin for site" do
    alice = users(:alice)
    my_blog = sites(:my_blog)

    assert alice.admin_for?(my_blog)
  end

  test "admin_for? returns false when user is not admin for site" do
    bob = users(:bob)
    my_blog = sites(:my_blog)

    assert_not bob.admin_for?(my_blog)
  end

  test "admin_for? returns false when user has no membership for site" do
    new_user = User.create!(email: "new@example.com", password: "password123456")
    my_blog = sites(:my_blog)

    assert_not new_user.admin_for?(my_blog)
  end

  test "member_of? returns true when user has any membership for site" do
    bob = users(:bob)
    my_blog = sites(:my_blog)

    assert bob.member_of?(my_blog)
  end

  test "member_of? returns true when user is admin for site" do
    alice = users(:alice)
    my_blog = sites(:my_blog)

    assert alice.member_of?(my_blog)
  end

  test "member_of? returns false when user has no membership for site" do
    new_user = User.create!(email: "newuser@example.com", password: "password123456")
    my_blog = sites(:my_blog)

    assert_not new_user.member_of?(my_blog)
  end

  test "sites returns all sites user is a member of" do
    alice = users(:alice)
    my_blog = sites(:my_blog)

    assert_includes alice.sites, my_blog
  end

  test "destroying user destroys associated memberships" do
    alice = users(:alice)
    membership_id = memberships(:alice_my_blog_admin).id

    alice.destroy

    assert_not Membership.exists?(membership_id)
  end
end
