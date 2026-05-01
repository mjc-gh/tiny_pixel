# frozen_string_literal: true

class Admin::Users::ResendInvitationsController < AdminController
  def create
    @user = User.find(params[:user_id])

    if @user.pending_invitation?
      UserMailer.invitation(@user).deliver_later
      redirect_to admin_users_path, notice: t(".success")
    else
      redirect_to admin_users_path, alert: t(".not_pending")
    end
  end
end
