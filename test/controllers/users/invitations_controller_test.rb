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
end
