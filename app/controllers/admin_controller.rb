# frozen_string_literal: true

class AdminController < ApplicationController
  layout "admin"

  before_action :authenticate_admin

  def self.secret_password
    key = Rails.application.key_generator.generate_key("tiny_pixel_admin")

    Base64.urlsafe_encode64(key, padding: false)[0..31]
  end

  private

  def authenticate_admin
    authenticate_with_http_basic { |u, p| u == "tiny_pixel" && p == self.class.secret_password } ||
      request_http_basic_authentication
  end
end
