# frozen_string_literal: true

require "test_helper"

class AdminControllerTest < ActionDispatch::IntegrationTest
  test "secret_password returns string of 32 length" do
    assert_equal AdminController.secret_password.size, 32
  end
end
