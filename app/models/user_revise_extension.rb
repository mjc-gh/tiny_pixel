# frozen_string_literal: true

module UserReviseExtension
  def send_confirmation_instructions
    super if TinyPixel.email_delivery_supported?
  end

  def send_password_reset_instructions
    super if TinyPixel.email_delivery_supported?
  end
end
