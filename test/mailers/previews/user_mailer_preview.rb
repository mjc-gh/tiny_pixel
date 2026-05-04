# frozen_string_literal: true

class UserMailerPreview < ActionMailer::Preview
  def invitation
    user = User.first || User.new(email: "preview@example.com")
    UserMailer.invitation(user)
  end
end
