# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def invitation(user)
    @user = user
    @invitation_url = users_invitation_url(token: @user.generate_token_for(:invitation_code))
    mail(to: @user.email, subject: t(".subject"))
  end
end
