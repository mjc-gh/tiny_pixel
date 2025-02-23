# frozen_string_literal: true

require "test_helper"

class IngestorTest < ActiveSupport::TestCase
  def app = Ingestor.new(->(env) { [200, {}, ""] })
  def env(path, method) = Rack::MockRequest.env_for(path, method:)

  test "post request with beacon route" do
    status, = app.call(env("/v1/beacon", :post))

    assert_equal 204, status
  end

  test "get request with beacon route" do
    status, = app.call(env("/v1/beacon", :get))

    assert_equal 200, status
  end

  test "other route" do
    status, = app.call(env("/other/path", :get))

    assert_equal 200, status
  end
end
