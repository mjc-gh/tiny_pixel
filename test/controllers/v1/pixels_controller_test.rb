# frozen_string_literal: true

require "test_helper"

class V1::PixelsControllerTest < ActionDispatch::IntegrationTest
  def self.headers(origin: "mypersonal.blog", ua: :iphone)
    { "HTTP_USER_AGENT" => user_agents[ua] }
  end

  def self.user_agents
    @user_agents ||= {
      iphone: "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
    }
  end

  def self.valid_payload
    { ev: "view", h: "michaeljcoyne.me", p: "/about", pid: "ABCD1234", qs: {}, r: "https://duckduckgo.com/" }
  end

  delegate :headers, :user_agents, :valid_payload, to: :class

  {
    "unknown pid param" => [valid_payload.merge(pid: "UNKN123"), headers],
    "missing pid param" => [valid_payload.without(:pid), headers],
    "missing host param" => [valid_payload.without(:h), headers],
    "missing path param" => [valid_payload.without(:p), headers],
    "missing user_agent" => [valid_payload, headers.without("HTTP_USER_AGENT")]
  }.each do |test_case, (params, headers)|
    test "post invalid pixel with #{test_case}" do
      get(v1_pixels_path, params:, headers:)

      assert_response :bad_request
    end
  end

  test "post valid pixel creates new visitor and page view" do
    assert_difference "Visitor.count" do
      assert_difference "PageView.count" do
        get(v1_pixels_path, params: valid_payload, headers:)
      end
    end

    assert_response :success
    assert_equal "image/gif", response.header["Content-Type"]
  end
end
