# frozen_string_literal: true

class V1::PixelsController < ActionController::Metal
  GIF_BODY = Base64.decode64("R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7").freeze

  def create
    pixel_request = PixelRequest.from_incoming(request, params)

    if pixel_request.valid?
      pixel_request.process!

      pixel_response
    else
      invalid_response
    end
  end

  private

  def pixel_response
    self.status = 200
    self.headers["Content-Type"] = "image/gif"
    self.response_body = GIF_BODY
  end

  def invalid_response
    self.status = 400
    self.response_body = "400 Bad Request"
  end
end
