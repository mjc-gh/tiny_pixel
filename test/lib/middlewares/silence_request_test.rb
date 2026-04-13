# frozen_string_literal: true

require "test_helper"

class Middlewares::SilenceRequestTest < ActiveSupport::TestCase
  test "silences logger when path is in configured paths" do
    env = { "PATH_INFO" => "/health" }

    mock_app = Minitest::Mock.new
    mock_app.expect(:call, "response", [env])

    middleware = Middlewares::SilenceRequest.new(mock_app, paths: ["/health", "/status"])

    result = middleware.call(env)

    assert_equal "response", result
    mock_app.verify
  end

  test "does not silence logger when path is not in configured paths" do
    env = { "PATH_INFO" => "/api/events" }

    mock_app = Minitest::Mock.new
    mock_app.expect(:call, "response", [env])

    middleware = Middlewares::SilenceRequest.new(mock_app, paths: ["/health", "/status"])

    result = middleware.call(env)

    assert_equal "response", result
    mock_app.verify
  end
end
