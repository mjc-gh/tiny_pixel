# frozen_string_literal: true

require "test_helper"

class Users::PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user_with_reset = users(:charlie)
    @user_without_reset = users(:alice)
  end

  test "redirects to login when not authenticated" do
    get edit_users_password_reset_path
    assert_redirected_to login_url
  end

  test "redirects to password reset when accessing protected route with flag set" do
    login(@user_with_reset)
    get root_path
    assert_redirected_to edit_users_password_reset_path
  end

  test "allows access to password reset edit when flag is set" do
    login(@user_with_reset)
    get edit_users_password_reset_path
    assert_response :success
    assert_select "form"
  end

  test "redirects away from password reset when flag is not set" do
    login(@user_without_reset)
    get edit_users_password_reset_path
    assert_redirected_to root_path
  end

  test "successfully updates password and clears flag" do
    login(@user_with_reset)
    assert @user_with_reset.password_reset_required?

    patch users_password_reset_path, params: {
      user: {
        password: "new_password_123",
        password_confirmation: "new_password_123"
      }
    }

    assert_redirected_to root_path
    assert_equal I18n.t("users.password_resets.update.success"), flash[:notice]

    @user_with_reset.reload
    assert_not @user_with_reset.password_reset_required?
  end

  test "does not update with mismatched passwords" do
    login(@user_with_reset)
    assert @user_with_reset.password_reset_required?

    patch users_password_reset_path, params: {
      user: {
        password: "new_password_123",
        password_confirmation: "different_password"
      }
    }

    assert_response :unprocessable_entity
    assert_select "form"
    @user_with_reset.reload
    assert @user_with_reset.password_reset_required?
  end

  test "allows user without reset flag to access other protected routes" do
    login(@user_without_reset)
    get sites_url
    assert_response :success
  end

  test "user without reset flag cannot access password reset form" do
    login(@user_without_reset)
    get edit_users_password_reset_path
    assert_redirected_to root_path
  end

  test "allows logout during required password reset" do
    login(@user_with_reset)
    delete logout_path
    assert_redirected_to root_path
    assert_nil session[:user_id]
  end
end
