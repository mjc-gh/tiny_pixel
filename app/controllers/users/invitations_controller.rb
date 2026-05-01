# frozen_string_literal: true

class Users::InvitationsController < ApplicationController
  def show
    user = User.find_by_token_for(:invitation_code, params[:token])

    if user
      user.complete_invitation!
      login(user)
      redirect_to edit_users_password_reset_path
    else
      redirect_to root_path, alert: t(".invalid_token")
    end
  end
end
