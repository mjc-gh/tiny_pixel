# frozen_string_literal: true

require "test_helper"

class Admin::Users::ResendInvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
  end

  test "create with pending invitation sends email and redirects" do
    @user.update!(invited_at: Time.current, invitation_completed_at: nil)

    post admin_user_resend_invitation_path(@user), headers: admin_auth_headers

    assert_redirected_to admin_users_path
    assert_equal I18n.t("admin.users.resend_invitations.create.success"), flash[:notice]
  end

  test "create with pending invitation without auth headers is unauthorized" do
    @user.update!(invited_at: Time.current, invitation_completed_at: nil)

    assert_no_difference("ActionMailer::Base.deliveries.count") do
      post admin_user_resend_invitation_path(@user)
    end

    assert_response :unauthorized
  end

  test "create without pending invitation redirects with alert" do
    @user.update!(invited_at: nil, invitation_completed_at: nil)

    post admin_user_resend_invitation_path(@user), headers: admin_auth_headers

    assert_redirected_to admin_users_path
    assert_equal I18n.t("admin.users.resend_invitations.create.not_pending"), flash[:alert]
  end

  test "create with completed invitation redirects with alert" do
    @user.update!(invited_at: Time.current, invitation_completed_at: Time.current)

    post admin_user_resend_invitation_path(@user), headers: admin_auth_headers

    assert_redirected_to admin_users_path
    assert_equal I18n.t("admin.users.resend_invitations.create.not_pending"), flash[:alert]
  end
end
