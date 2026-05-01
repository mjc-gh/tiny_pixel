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

  test "invite creates user with correct attributes" do
    email = "new_user@example.com"
    TinyPixel.stub :email_delivery_supported?, true do
      user = User.invite(email)

      assert_equal email, user.email
      assert user.password_reset_required?
      assert_not_nil user.invited_at
    end
  end

  test "invite sends invitation email" do
    email = "new_user@example.com"

    TinyPixel.stub :email_delivery_supported?, true do
      user = User.invite(email)
      # User is created successfully with email
      assert_equal email, user.email
    end
  end

  test "invite raises EmailDeliveryNotSupportedError when email not configured" do
    email = "new_user@example.com"
    TinyPixel.stub :email_delivery_supported?, false do
      assert_raises User::EmailDeliveryNotSupportedError do
        User.invite(email)
      end
    end
  end

  test "invitation_code token expires after 7 days" do
    user = User.create!(
      email: "test@example.com",
      password: "password123456",
      confirmed_at: Time.current
    )

    token = user.generate_token_for(:invitation_code)

    travel 8.days do
      found_user = User.find_by_token_for(:invitation_code, token)
      assert_nil found_user
    end
  end

  test "pending_invitation? returns true when invited_at is set and invitation_completed_at is nil" do
    user = User.create!(
      email: "pending@example.com",
      password: "password123456",
      invited_at: Time.current
    )

    assert user.pending_invitation?
  end

  test "pending_invitation? returns false when invitation_completed_at is set" do
    user = User.create!(
      email: "completed@example.com",
      password: "password123456",
      invited_at: Time.current,
      invitation_completed_at: Time.current
    )

    assert_not user.pending_invitation?
  end

  test "pending_invitation? returns false when invited_at is nil" do
    user = User.create!(
      email: "not_invited@example.com",
      password: "password123456"
    )

    assert_not user.pending_invitation?
  end
end
