# frozen_string_literal: true

module Digestable
  private

  def sha_256(&block)
    Digest::SHA256.new.tap(&block)
  end
end
