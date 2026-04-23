# frozen_string_literal: true

class AdminController < ApplicationController
  layout "admin"

  def self.secret_password
    key = Rails.application.key_generator.generate_key("tiny_pixel_admin")

    [key].pack("m0")[0..31]
  end

  http_basic_authenticate_with name: "tiny_pixel", password: secret_password
end
