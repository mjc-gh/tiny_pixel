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

  test "detects existing session within 30 minutes" do
    site = sites(:my_blog)
    property_id = site.property_id

    req1 = FakeRequest.new("1.2.3.4", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
    pr1 = PixelRequest.from_incoming(req1, { pid: property_id, p: "/", h: "blog.net" })
    pr1.process!

    # Verify first request created a new session and visit
    assert pr1.instance_variable_get(:@new_visit)
    assert pr1.instance_variable_get(:@new_session)

    # Create second request with same visitor within 30 minutes
    req2 = FakeRequest.new("1.2.3.4", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
    pr2 = PixelRequest.from_incoming(req2, { pid: property_id, p: "/about", h: "blog.net" })
    pr2.process!

    # Verify second request is NOT a new visit (same visitor)
    refute pr2.instance_variable_get(:@new_visit)
    # When a PageView exists within 30 minutes, new_session should be false
    # This tests the PageView.exists? branch
    visitor_digest = pr2.send(:visitor_digest)
    existing_page_view = PageView.find_by(visitor_digest:)
    assert_not_nil existing_page_view, "PageView should exist from first request"

    # The second process call should find this existing PageView
    # and NOT set new_session to true
    refute pr2.instance_variable_get(:@new_session)
  end

  test "handles IPAddr::Error for invalid IP addresses" do
    site = sites(:my_blog)
    property_id = site.property_id

    pr = PixelRequest.new
    pr.remote_ip = "invalid-ip-address-that-will-cause-error"

    original_maxmind = TinyPixel.instance_variable_get(:@geo_db)

    class MockGeodb
      def get(_ip)
        raise IPAddr::Error, "Invalid IP format"
      end
    end

    TinyPixel.instance_variable_set(:@geo_db, MockGeodb.new)

    begin
      # Test that visitor_country returns DEFAULT_COUNTRY_CODE when IPAddr::Error occurs
      country = pr.send(:visitor_country)
      assert_equal PixelRequest::DEFAULT_COUNTRY_CODE, country
    ensure
      # Restore original
      TinyPixel.instance_variable_set(:@geo_db, original_maxmind)
    end
  end

  test "classifies unknown OS family as device type 'other'" do
    unknown_os_user_agent = "Mozilla/5.0 (UnknownOS/1.0) AppleWebKit/537.36"

    req = FakeRequest.new("1.2.3.4", unknown_os_user_agent)
    hash = { device_type: :other }

    assert_changes -> { Visitor.where(hash).count }, "missing visitor with device_type 'other'", to: 1 do
      pr = PixelRequest.from_incoming(req, { pid: sites(:my_blog).property_id, p: "/", h: "blog.net" })
      pr.process!
    end
  end

  test "from_incoming assigns all parameters correctly" do
    site = sites(:my_blog)
    req = FakeRequest.new("192.168.1.1", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")

    params = {
      pid: site.property_id,
      p: "/products",
      h: "example.com",
      qs: "utm_source=google&utm_medium=cpc",
      r: "https://google.com"
    }

    pr = PixelRequest.from_incoming(req, params)

    assert_equal site.property_id, pr.property_id
    assert_equal "/products", pr.pathname
    assert_equal "example.com", pr.hostname
    assert_equal "utm_source=google&utm_medium=cpc", pr.attribution
    assert_equal "https://google.com", pr.referrer
    assert_equal "192.168.1.1", pr.remote_ip
    assert_equal "Mozilla/5.0 (Windows NT 10.0; Win64; x64)", pr.user_agent
  end

  test "validation fails without required attributes" do
    pr = PixelRequest.new

    refute pr.valid?
    assert pr.errors[:hostname].any?
    assert pr.errors[:pathname].any?
    assert pr.errors[:property_id].any?
    assert pr.errors[:remote_ip].any?
    assert pr.errors[:user_agent].any?
  end

  test "validation fails when missing hostname" do
    pr = PixelRequest.new
    pr.pathname = "/"
    pr.property_id = sites(:my_blog).property_id
    pr.remote_ip = "1.2.3.4"
    pr.user_agent = "Mozilla/5.0"

    refute pr.valid?
    assert pr.errors[:hostname].any?
  end

  test "validation fails when missing pathname" do
    pr = PixelRequest.new
    pr.hostname = "example.com"
    pr.property_id = sites(:my_blog).property_id
    pr.remote_ip = "1.2.3.4"
    pr.user_agent = "Mozilla/5.0"

    refute pr.valid?
    assert pr.errors[:pathname].any?
  end

  test "visitor_digest is consistent for same inputs" do
    site = sites(:my_blog)
    req = FakeRequest.new("1.2.3.4", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")

    pr1 = PixelRequest.from_incoming(req, { pid: site.property_id, p: "/", h: "blog.net" })
    pr2 = PixelRequest.from_incoming(req, { pid: site.property_id, p: "/", h: "blog.net" })

    assert_equal pr1.send(:visitor_digest), pr2.send(:visitor_digest)
  end

  test "page_view_digest differs for different pathnames" do
    site = sites(:my_blog)
    req = FakeRequest.new("1.2.3.4", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")

    pr1 = PixelRequest.from_incoming(req, { pid: site.property_id, p: "/page1", h: "blog.net" })
    pr2 = PixelRequest.from_incoming(req, { pid: site.property_id, p: "/page2", h: "blog.net" })

    refute_equal pr1.send(:page_view_digest), pr2.send(:page_view_digest)
  end

  test "process! returns nil" do
    site = sites(:my_blog)
    req = FakeRequest.new("1.2.3.4", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    pr = PixelRequest.from_incoming(req, { pid: site.property_id, p: "/", h: "blog.net" })

    result = pr.process!
    assert_nil result
  end
end
