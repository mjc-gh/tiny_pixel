# frozen_string_literal: true

require "test_helper"

class Users::InvitationsControllerTest < ActionDispatch::IntegrationTest
  test "valid token logs in user and redirects to password reset" do
    user = User.create!(
      email: "test@example.com",
      password: "password123456",
      password_reset_required: true
    )

    token = user.generate_token_for(:invitation_code)

    get users_invitation_url(token: token)

    assert_redirected_to edit_users_password_reset_path
    assert_equal user.id, session[:user_id]
    user.reload
    assert_not_nil user.invitation_completed_at
  end

  test "invalid token redirects to root with alert" do
    invalid_token = "invalid_token_value"

    get users_invitation_url(token: invalid_token)

    assert_redirected_to root_path
    assert_equal "The invitation link is invalid or has expired", flash[:alert]
  end

  test "expired token redirects to root with alert" do
    user = User.create!(
      email: "test@example.com",
      password: "password123456",
      password_reset_required: true,
    )

    token = user.generate_token_for(:invitation_code)

    travel 8.days do
      get users_invitation_url(token: token)

      assert_redirected_to root_path
      assert_equal "The invitation link is invalid or has expired", flash[:alert]
    end
  end

  test "valid token does not overwrite existing invitation_completed_at" do
    original_completion_time = 1.day.ago
    user = User.create!(
      email: "test@example.com",
      password: "password123456",
      password_reset_required: true,
      invitation_completed_at: original_completion_time
    )

    token = user.generate_token_for(:invitation_code)

    get users_invitation_url(token: token)

    user.reload
    # Check that the time is approximately the same (within 1 second)
    assert((user.invitation_completed_at - original_completion_time).abs < 1.second)
  end
end
