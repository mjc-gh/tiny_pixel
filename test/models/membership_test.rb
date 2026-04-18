# frozen_string_literal: true

require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  test "role defaults to member" do
    new_site = Site.new(name: "New Site")
    new_site.cycle_salt
    new_site.save!

    membership = Membership.new(user: users(:alice), site: new_site)

    assert_equal "member", membership.role
  end

  test "duplicate user and site combination is invalid" do
    alice = users(:alice)
    my_blog = sites(:my_blog)

    duplicate_membership = Membership.new(user: alice, site: my_blog, role: :member)

    assert_not duplicate_membership.valid?
    assert_includes duplicate_membership.errors[:user_id], "is already a member of this site"
  end

  test "same user can be member of different sites" do
    alice = users(:alice)
    new_site = Site.new(name: "Another Site")
    new_site.cycle_salt
    new_site.save!

    membership = Membership.new(user: alice, site: new_site, role: :member)

    assert membership.valid?
  end

  test "different users can be members of same site" do
    new_user = User.create!(email: "newuser@example.com", password: "password123456")
    my_blog = sites(:my_blog)

    membership = Membership.new(user: new_user, site: my_blog, role: :member)

    assert membership.valid?
  end
end
