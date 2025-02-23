# frozen_string_literal: true

require "test_helper"

class PixelRequestTest < ActiveSupport::TestCase
  test "with unknown property id" do
    pr = PixelRequest.new
    pr.property_id = "UNKN123"

    refute pr.valid?
    assert pr.errors.where(:property_id, :unknown)
  end

  # User-Agent tests

  FakeRequest = Data.define(:remote_ip, :user_agent)

  {
    %i[chrome desktop] => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36",
    %i[chrome mobile] => "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.6943.121 Mobile Safari/537.36",
    %i[safari mobile] => "Mozilla/5.0 (iPhone; CPU iPhone OS 17_7_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.3 Mobile/15E148 Safari/604.1",
    %i[other crawler] => "Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/W.X.Y.Z Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
  }.each do |values, user_agent|
    test "with #{values * ' '}" do
      req = FakeRequest.new("1.2.3.4", user_agent)
      hash = %i[browser device_type].zip(values).to_h

      assert_changes -> { Visitor.where(hash).count }, "missing visitor with #{hash.inspect}", to: 1 do
        pr = PixelRequest.from_incoming(req, { pid: sites(:my_blog).property_id, p: "/", h: "blog.net" })
        pr.process!
      end
    end
  end
end
