# frozen_string_literal: true

# :nocov:
class ApplicationMailer < ActionMailer::Base
  default from: -> { TinyPixel.email_delivery_from_address }
  layout "mailer"
end
# :nocov:
