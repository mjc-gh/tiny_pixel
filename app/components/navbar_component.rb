# frozen_string_literal: true

class NavbarComponent < ViewComponent::Base
  def initialize(user:)
    @user = user
  end

  def signed_in?
    @user.present?
  end
end
