# frozen_string_literal: true

require "test_helper"

class PixelRequestTest < ActiveSupport::TestCase
  test "with unknown property id" do
    pr = PixelRequest.new
    pr.property_id = "UNKN123"

    refute pr.valid?
    assert pr.errors.where(:property_id, :unknown)
  end
end
