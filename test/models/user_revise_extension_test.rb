# frozen_string_literal: true

require "test_helper"

class UserReviseExtensionTest < ActiveSupport::TestCase
  class Model
    prepend UserReviseExtension

    def send_confirmation_instructions = raise
    def send_password_reset_instructions = raise
  end

  test "send_confirmation_instructions when email delivery is supported" do
    TinyPixel.stub :email_delivery_supported?, true do
      model = Model.new
      assert_raises(RuntimeError) { model.send_confirmation_instructions }
    end
  end

  test "send_confirmation_instructions when email delivery is not supported" do
    TinyPixel.stub :email_delivery_supported?, false do
      model = Model.new
      assert_nil model.send_confirmation_instructions
    end
  end

  test "send_password_reset_instructions when email delivery is supported" do
    TinyPixel.stub :email_delivery_supported?, true do
      model = Model.new
      assert_raises(RuntimeError) { model.send_password_reset_instructions }
    end
  end

  test "send_password_reset_instructions when email delivery is not supported" do
    TinyPixel.stub :email_delivery_supported?, false do
      model = Model.new
      assert_nil model.send_password_reset_instructions
    end
  end
end
