# frozen_string_literal: true

require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
  end

  test "index with auth headers is successful" do
    get admin_users_path, headers: admin_auth_headers

    assert_response :success
    assert_select "h1", I18n.t("admin.users.index.title")
  end

  test "index without auth headers is unauthorized" do
    get admin_users_path

    assert_response :unauthorized
  end

  test "index displays all users" do
    # Create additional test user
    User.create!(
      email: "new_user@example.com",
      password: "valid_password_12",
      password_confirmation: "valid_password_12"
    )

    get admin_users_path, headers: admin_auth_headers

    assert_response :success
    assert_select "tbody tr", count: User.count
  end

  test "new with auth headers is successful" do
    get new_admin_user_path, headers: admin_auth_headers

    assert_response :success
    assert_select "form"
    assert_select "[name=?]", "user[email]"
  end

  test "new without auth headers is unauthorized" do
    get new_admin_user_path

    assert_response :unauthorized
  end

  test "create with valid email and auth headers creates user" do
    assert_difference("User.count") do
      post admin_users_path, headers: admin_auth_headers, params: {
        user: { email: "newuser@example.com" }
      }
    end

    new_user = User.find_by(email: "newuser@example.com")
    assert_not_nil new_user
    assert new_user.password_reset_required?
    assert_not_nil new_user.confirmed_at
    assert_redirected_to admin_user_path(new_user)
  end

  test "create without auth headers is unauthorized" do
    assert_no_difference("User.count") do
      post admin_users_path, params: {
        user: { email: "newuser@example.com" }
      }
    end

    assert_response :unauthorized
  end

  test "create with invalid email returns unprocessable_entity" do
    assert_no_difference("User.count") do
      post admin_users_path, headers: admin_auth_headers, params: {
        user: { email: "invalid-email" }
      }
    end

    assert_response :unprocessable_entity
    assert_select "form"
  end

  test "create with duplicate email returns unprocessable_entity" do
    assert_no_difference("User.count") do
      post admin_users_path, headers: admin_auth_headers, params: {
        user: { email: @user.email }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create with missing email returns unprocessable_entity" do
    assert_no_difference("User.count") do
      post admin_users_path, headers: admin_auth_headers, params: {
        user: { email: "" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "show with auth headers displays user email" do
    new_user = User.create!(
      email: "showtest@example.com",
      password: "valid_password_12",
      password_confirmation: "valid_password_12",
      password_reset_required: true,
      confirmed_at: Time.current
    )

    get admin_user_path(new_user), headers: admin_auth_headers

    assert_response :success
    assert_select "h1", I18n.t("admin.users.show.title")
    assert_match new_user.email, response.body
  end

  test "show without auth headers is unauthorized" do
    get admin_user_path(@user)

    assert_response :unauthorized
  end

  test "create redirects to show with temp password" do
    post admin_users_path, headers: admin_auth_headers, params: {
      user: { email: "redirect_test@example.com" }
    }

    new_user = User.find_by(email: "redirect_test@example.com")
    assert_not_nil new_user
    assert_redirected_to admin_user_path(new_user)
  end

  test "create with password method creates user with confirmed_at" do
    assert_difference("User.count") do
      post admin_users_path, headers: admin_auth_headers, params: {
        user: { email: "password_method@example.com" },
        creation_method: "password"
      }
    end

    new_user = User.find_by(email: "password_method@example.com")
    assert_not_nil new_user
    assert new_user.password_reset_required?
    assert_not_nil new_user.confirmed_at
    assert_redirected_to admin_user_path(new_user)
  end

  test "create with invite method sends invitation email" do
    TinyPixel.stub :email_delivery_supported?, true do
      assert_difference("User.count") do
        assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
          post admin_users_path, headers: admin_auth_headers, params: {
            user: { email: "invite_method@example.com" },
            creation_method: "invite"
          }
        end
      end

      new_user = User.find_by(email: "invite_method@example.com")
      assert_not_nil new_user
      assert_redirected_to admin_users_path
    end
  end

  test "create with invite method does not set confirmed_at" do
    TinyPixel.stub :email_delivery_supported?, true do
      post admin_users_path, headers: admin_auth_headers, params: {
        user: { email: "invite_unconfirmed@example.com" },
        creation_method: "invite"
      }

      new_user = User.find_by(email: "invite_unconfirmed@example.com")
      assert_not_nil new_user
      assert_nil new_user.confirmed_at
      assert new_user.password_reset_required?
    end
  end

  test "create with invite method when email not supported falls back to password" do
    TinyPixel.stub :email_delivery_supported?, false do
      assert_difference("User.count") do
        post admin_users_path, headers: admin_auth_headers, params: {
          user: { email: "fallback_test@example.com" },
          creation_method: "invite"
        }
      end

      new_user = User.find_by(email: "fallback_test@example.com")
      assert_not_nil new_user
      assert_not_nil new_user.confirmed_at
      assert_redirected_to admin_user_path(new_user)
    end
  end

  test "create with invite method and invalid email returns unprocessable_entity" do
    TinyPixel.stub :email_delivery_supported?, true do
      assert_no_difference("User.count") do
        post admin_users_path, headers: admin_auth_headers, params: {
          user: { email: "invalid-email" },
          creation_method: "invite"
        }
      end

      assert_response :unprocessable_entity
      assert_select "form"
    end
  end

  test "create with invite method and duplicate email returns unprocessable_entity" do
    TinyPixel.stub :email_delivery_supported?, true do
      assert_no_difference("User.count") do
        post admin_users_path, headers: admin_auth_headers, params: {
          user: { email: @user.email },
          creation_method: "invite"
        }
      end

      assert_response :unprocessable_entity
    end
  end
end
