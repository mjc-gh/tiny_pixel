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

    req_1 = FakeRequest.new("1.2.3.4", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
    pr_1 = PixelRequest.from_incoming(req_1, { pid: property_id, p: "/", h: "blog.net" })
    pr_1.process!

    # Verify first request created a new session and visit
    assert pr_1.instance_variable_get(:@new_visit)
    assert pr_1.instance_variable_get(:@new_session)

    # Create second request with same visitor within 30 minutes
    req_2 = FakeRequest.new("1.2.3.4", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
    pr_2 = PixelRequest.from_incoming(req_2, { pid: property_id, p: "/about", h: "blog.net" })
    pr_2.process!

    # Verify second request is NOT a new visit (same visitor)
    refute pr_2.instance_variable_get(:@new_visit)
    # When a PageView exists within 30 minutes, new_session should be false
    # This tests the PageView.exists? branch
    visitor_digest = pr_2.send(:visitor_digest)
    existing_page_view = PageView.find_by(visitor_digest:)
    assert_not_nil existing_page_view, "PageView should exist from first request"

    # The second process call should find this existing PageView
    # and NOT set new_session to true
    refute pr_2.instance_variable_get(:@new_session)
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

  test "visitor_digest is consistent for same inputs" do
    site = sites(:my_blog)
    req = FakeRequest.new("1.2.3.4", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")

    pr_1 = PixelRequest.from_incoming(req, { pid: site.property_id, p: "/", h: "blog.net" })
    pr_2 = PixelRequest.from_incoming(req, { pid: site.property_id, p: "/", h: "blog.net" })

    assert_equal pr_1.send(:visitor_digest), pr_2.send(:visitor_digest)
  end

  test "page_view_digest differs for different pathnames" do
    site = sites(:my_blog)
    req = FakeRequest.new("1.2.3.4", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")

    pr_1 = PixelRequest.from_incoming(req, { pid: site.property_id, p: "/page1", h: "blog.net" })
    pr_2 = PixelRequest.from_incoming(req, { pid: site.property_id, p: "/page2", h: "blog.net" })

    refute_equal pr_1.send(:page_view_digest), pr_2.send(:page_view_digest)
  end

  test "process! returns nil" do
    site = sites(:my_blog)
    req = FakeRequest.new("1.2.3.4", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    pr = PixelRequest.from_incoming(req, { pid: site.property_id, p: "/", h: "blog.net" })

    result = pr.process!
    assert_nil result
  end

  # Referrer parsing tests

  test "pageview created with referrer gets parsed hostname and pathname" do
    site = sites(:my_blog)
    req = FakeRequest.new("1.2.3.4", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")

    pr = PixelRequest.from_incoming(req, {
      pid: site.property_id,
      p: "/products",
      h: "example.com",
      r: "https://www.google.com/search?q=ruby+on+rails"
    })
    pr.process!

    visitor_digest = pr.send(:visitor_digest)
    page_view = PageView.find_by(visitor_digest:)

    assert_not_nil page_view
    assert_equal "google.com", page_view.referrer_hostname
    assert_equal "/search", page_view.referrer_pathname
  end

  test "direct visits without referrer have nil parsed components" do
    site = sites(:my_blog)
    req = FakeRequest.new("1.2.3.4", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")

    pr = PixelRequest.from_incoming(req, {
      pid: site.property_id,
      p: "/",
      h: "example.com"
    })
    pr.process!

    visitor_digest = pr.send(:visitor_digest)
    page_view = PageView.find_by(visitor_digest:)

    assert_not_nil page_view
    assert_nil page_view.referrer_hostname
    assert_nil page_view.referrer_pathname
  end

  test "parsed_referrer caches result" do
    site = sites(:my_blog)
    req = FakeRequest.new("1.2.3.4", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")

    pr = PixelRequest.from_incoming(req, {
      pid: site.property_id,
      p: "/",
      h: "example.com",
      r: "https://example.com/page"
    })

    result_1 = pr.send(:parsed_referrer)
    result_2 = pr.send(:parsed_referrer)

    assert_same result_1, result_2
  end

  # is_unique handling

  test "first pageview of path is marked as unique" do
    site = sites(:my_blog)
    req = FakeRequest.new("5.6.7.8", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    pr = PixelRequest.from_incoming(req, { pid: site.property_id, p: "/blog", h: "blog.net" })
    pr.process!

    assert pr.instance_variable_get(:@is_unique)
  end

  test "second pageview of same path by same visitor is not unique" do
    site = sites(:my_blog)
    property_id = site.property_id

    first_req = FakeRequest.new("6.7.8.9", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    first_pr = PixelRequest.from_incoming(first_req, { pid: property_id, p: "/blog", h: "blog.net" })
    first_pr.process!

    assert first_pr.instance_variable_get(:@is_unique)

    second_req = FakeRequest.new("6.7.8.9", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    second_pr = PixelRequest.from_incoming(second_req, { pid: property_id, p: "/blog", h: "blog.net" })
    second_pr.process!

    refute second_pr.instance_variable_get(:@is_unique)
  end

  test "different paths are unique independently" do
    site = sites(:my_blog)
    property_id = site.property_id

    first_req = FakeRequest.new("7.8.9.10", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    first_pr = PixelRequest.from_incoming(first_req, { pid: property_id, p: "/blog", h: "blog.net" })
    first_pr.process!

    assert first_pr.instance_variable_get(:@is_unique)

    second_req = FakeRequest.new("7.8.9.10", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    second_pr = PixelRequest.from_incoming(second_req, { pid: property_id, p: "/about", h: "blog.net" })
    second_pr.process!

    assert second_pr.instance_variable_get(:@is_unique)
  end

  test "is_unique resets after 24 hours for daily salt cycle" do
    site = sites(:my_blog)
    property_id = site.property_id

    first_req = FakeRequest.new("8.9.10.11", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    first_pr = PixelRequest.from_incoming(first_req, { pid: property_id, p: "/blog", h: "blog.net" })
    first_pr.process!

    assert first_pr.instance_variable_get(:@is_unique)

    travel_to 25.hours.from_now do
      second_req = FakeRequest.new("8.9.10.11", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      second_pr = PixelRequest.from_incoming(second_req, { pid: property_id, p: "/blog", h: "blog.net" })
      second_pr.process!

      assert second_pr.instance_variable_get(:@is_unique)
    end
  end

  test "is_unique resets at beginning of week for weekly salt cycle" do
    site = Site.create!(name: "Weekly Site", salt: "placeholder_weekly", salt_duration: :weekly)
    property_id = site.property_id
    SiteCache.clear

    # Create first pageview on a Monday
    monday = Time.current.beginning_of_week
    travel_to monday do
      req_1 = FakeRequest.new("23.24.25.26", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      pr_1 = PixelRequest.from_incoming(req_1, { pid: property_id, p: "/blog", h: "weekly.net" })
      pr_1.process!

      assert pr_1.instance_variable_get(:@is_unique)
    end

    # Same visitor on Wednesday (same week) - not unique
    wednesday = monday + 2.days
    travel_to wednesday do
      req_2 = FakeRequest.new("23.24.25.26", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      pr_2 = PixelRequest.from_incoming(req_2, { pid: property_id, p: "/blog", h: "weekly.net" })
      pr_2.process!

      refute pr_2.instance_variable_get(:@is_unique)
    end

    # Same visitor on next Monday (new week) - unique
    next_monday = monday + 1.week
    travel_to next_monday do
      req_3 = FakeRequest.new("23.24.25.26", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      pr_3 = PixelRequest.from_incoming(req_3, { pid: property_id, p: "/blog", h: "weekly.net" })
      pr_3.process!

      assert pr_3.instance_variable_get(:@is_unique)
    end
  end

  test "is_unique resets at beginning of month for monthly salt cycle" do
    site = Site.create!(name: "Monthly Site", salt: "placeholder_monthly", salt_duration: :monthly)
    property_id = site.property_id
    SiteCache.clear

    # Create first pageview on the 5th of the month
    month_start = Time.current.beginning_of_month
    fifth = month_start + 4.days

    travel_to fifth do
      req_1 = FakeRequest.new("24.25.26.27", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      pr_1 = PixelRequest.from_incoming(req_1, { pid: property_id, p: "/blog", h: "monthly.net" })
      pr_1.process!

      assert pr_1.instance_variable_get(:@is_unique)
    end

    # Same visitor on the 25th (same month) - not unique
    twenty_fifth = month_start + 24.days
    travel_to twenty_fifth do
      req_2 = FakeRequest.new("24.25.26.27", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      pr_2 = PixelRequest.from_incoming(req_2, { pid: property_id, p: "/blog", h: "monthly.net" })
      pr_2.process!

      refute pr_2.instance_variable_get(:@is_unique)
    end

    # Same visitor on 1st of next month (new month) - unique
    next_month_first = month_start + 1.month
    travel_to next_month_first do
      req_3 = FakeRequest.new("24.25.26.27", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      pr_3 = PixelRequest.from_incoming(req_3, { pid: property_id, p: "/blog", h: "monthly.net" })
      pr_3.process!

      assert pr_3.instance_variable_get(:@is_unique)
    end
  end

  test "first pageview is unique for all salt durations" do
    %i[daily weekly monthly].each do |duration|
      site = Site.create!(name: "Test #{duration}", salt: "test_#{duration}", salt_duration: duration)
      property_id = site.property_id
      SiteCache.clear

      req = FakeRequest.new("30.31.32.33", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      pr = PixelRequest.from_incoming(req, { pid: property_id, p: "/test", h: "test.net" })
      pr.process!

      assert pr.instance_variable_get(:@is_unique), "First pageview should be unique for #{duration} salt cycle"

      # Clean up
      site.destroy
      SiteCache.clear
    end
  end

  test "different paths are unique independently for all salt durations" do
    %i[daily weekly monthly].each do |duration|
      site = Site.create!(name: "Path Test #{duration}", salt: "path_test_#{duration}", salt_duration: duration)
      property_id = site.property_id
      SiteCache.clear

      first_req = FakeRequest.new("31.32.33.34", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      first_pr = PixelRequest.from_incoming(first_req, { pid: property_id, p: "/path1", h: "path-test.net" })
      first_pr.process!

      assert first_pr.instance_variable_get(:@is_unique), "First path should be unique for #{duration} salt cycle"

      second_req = FakeRequest.new("31.32.33.34", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      second_pr = PixelRequest.from_incoming(second_req, { pid: property_id, p: "/path2", h: "path-test.net" })
      second_pr.process!

      assert second_pr.instance_variable_get(:@is_unique), "Different path should be unique for #{duration} salt cycle"

      # Clean up
      site.destroy
      SiteCache.clear
    end
  end

  test "different visitors on same path are both unique" do
    site = sites(:my_blog)
    property_id = site.property_id

    first_req = FakeRequest.new("9.10.11.12", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    first_pr = PixelRequest.from_incoming(first_req, { pid: property_id, p: "/blog", h: "blog.net" })
    first_pr.process!

    assert first_pr.instance_variable_get(:@is_unique)

    second_req = FakeRequest.new("10.11.12.13", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    second_pr = PixelRequest.from_incoming(second_req, { pid: property_id, p: "/blog", h: "blog.net" })
    second_pr.process!

    assert second_pr.instance_variable_get(:@is_unique)
  end

  # Session timeout configuration tests

  test "session timeout uses site configuration instead of hardcoded value" do
    site = Site.create!(name: "Short Timeout Site", salt: "placeholder", session_timeout_minutes: 10)
    property_id = site.property_id
    SiteCache.clear

    req_1 = FakeRequest.new("111.112.113.114", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    pr_1 = PixelRequest.from_incoming(req_1, { pid: property_id, p: "/", h: "short-timeout.net" })
    pr_1.process!

    assert pr_1.instance_variable_get(:@new_session)

    travel_to 11.minutes.from_now do
      req_2 = FakeRequest.new("111.112.113.114", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      pr_2 = PixelRequest.from_incoming(req_2, { pid: property_id, p: "/about", h: "short-timeout.net" })
      pr_2.process!

      assert pr_2.instance_variable_get(:@new_session)
    end
  end

  test "pageview within custom session timeout is same session" do
    site = Site.create!(name: "Long Timeout Site", salt: "placeholder", session_timeout_minutes: 60)
    property_id = site.property_id
    SiteCache.clear

    req_1 = FakeRequest.new("112.113.114.115", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    pr_1 = PixelRequest.from_incoming(req_1, { pid: property_id, p: "/", h: "long-timeout.net" })
    pr_1.process!

    travel_to 45.minutes.from_now do
      req_2 = FakeRequest.new("112.113.114.115", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      pr_2 = PixelRequest.from_incoming(req_2, { pid: property_id, p: "/about", h: "long-timeout.net" })
      pr_2.process!

      refute pr_2.instance_variable_get(:@new_session)
    end
  end

  # Duration calculation tests

  test "first pageview has nil duration" do
    site = sites(:my_blog)
    req = FakeRequest.new("13.14.15.16", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    pr = PixelRequest.from_incoming(req, { pid: site.property_id, p: "/", h: "blog.net" })
    pr.process!

    page_view = PageView.find_by(visitor_digest: pr.send(:visitor_digest))

    assert_nil page_view.duration
  end

  test "second pageview within session updates previous pageview duration" do
    site = sites(:my_blog)
    property_id = site.property_id
    base_time = Time.current.change(usec: 0)

    travel_to base_time do
      req_1 = FakeRequest.new("14.15.16.17", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      pr_1 = PixelRequest.from_incoming(req_1, { pid: property_id, p: "/", h: "blog.net" })
      pr_1.process!
    end

    visitor_digest = PixelRequest.calculate_visitor_digest(
      salt: site.salt,
      remote_ip: "14.15.16.17",
      user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
      hostname: "blog.net"
    )

    first_page_view = PageView.find_by(visitor_digest:, pathname: "/")
    assert_nil first_page_view.duration

    travel_to base_time + 5.minutes do
      req_2 = FakeRequest.new("14.15.16.17", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      pr_2 = PixelRequest.from_incoming(req_2, { pid: property_id, p: "/about", h: "blog.net" })
      pr_2.process!

      updated_first_page_view = PageView.find_by(visitor_digest:, pathname: "/")
      assert_equal 300, updated_first_page_view.duration
    end
  end

  test "duration calculation is accurate for multiple successive pageviews" do
    site = sites(:my_blog)
    property_id = site.property_id
    base_time = Time.current.change(usec: 0)

    travel_to base_time do
      req_1 = FakeRequest.new("15.16.17.18", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      pr_1 = PixelRequest.from_incoming(req_1, { pid: property_id, p: "/page1", h: "blog.net" })
      pr_1.process!
    end

    visitor_digest = PixelRequest.calculate_visitor_digest(
      salt: site.salt,
      remote_ip: "15.16.17.18",
      user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
      hostname: "blog.net"
    )

    travel_to base_time + 2.minutes do
      req_2 = FakeRequest.new("15.16.17.18", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      pr_2 = PixelRequest.from_incoming(req_2, { pid: property_id, p: "/page2", h: "blog.net" })
      pr_2.process!
    end

    travel_to base_time + 7.minutes do
      req_3 = FakeRequest.new("15.16.17.18", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      pr_3 = PixelRequest.from_incoming(req_3, { pid: property_id, p: "/page3", h: "blog.net" })
      pr_3.process!
    end

    page_view_1 = PageView.find_by(visitor_digest:, pathname: "/page1")
    page_view_2 = PageView.find_by(visitor_digest:, pathname: "/page2")
    page_view_3 = PageView.find_by(visitor_digest:, pathname: "/page3")

    assert_equal 120, page_view_1.duration
    assert_equal 300, page_view_2.duration
    assert_nil page_view_3.duration
  end

  test "duration is not calculated for pageview outside session window" do
    site = sites(:my_blog)
    property_id = site.property_id
    base_time = Time.current.change(usec: 0)

    travel_to base_time do
      req_1 = FakeRequest.new("16.17.18.19", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      pr_1 = PixelRequest.from_incoming(req_1, { pid: property_id, p: "/", h: "blog.net" })
      pr_1.process!
    end

    visitor_digest = PixelRequest.calculate_visitor_digest(
      salt: site.salt,
      remote_ip: "16.17.18.19",
      user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
      hostname: "blog.net"
    )

    travel_to base_time + 35.minutes do
      req_2 = FakeRequest.new("16.17.18.19", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      pr_2 = PixelRequest.from_incoming(req_2, { pid: property_id, p: "/about", h: "blog.net" })
      pr_2.process!
    end

    page_view_1 = PageView.find_by(visitor_digest:, pathname: "/")
    page_view_2 = PageView.find_by(visitor_digest:, pathname: "/about")

    assert_nil page_view_1.duration
    assert_nil page_view_2.duration
  end

  # Bounce detection tests

  test "first pageview is marked as bounced" do
    site = sites(:my_blog)
    req = FakeRequest.new("17.18.19.20", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    pr = PixelRequest.from_incoming(req, { pid: site.property_id, p: "/", h: "blog.net" })
    pr.process!

    page_view = PageView.find_by(visitor_digest: pr.send(:visitor_digest))

    assert page_view.bounced
  end

  test "second pageview within session marks previous pageview as not bounced" do
    site = sites(:my_blog)
    property_id = site.property_id

    req_1 = FakeRequest.new("18.19.20.21", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    pr_1 = PixelRequest.from_incoming(req_1, { pid: property_id, p: "/", h: "blog.net" })
    pr_1.process!
    visitor_digest = pr_1.send(:visitor_digest)

    first_page_view = PageView.find_by(visitor_digest:, pathname: "/")
    assert first_page_view.bounced

    travel_to 5.minutes.from_now do
      req_2 = FakeRequest.new("18.19.20.21", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      pr_2 = PixelRequest.from_incoming(req_2, { pid: property_id, p: "/about", h: "blog.net" })
      pr_2.process!

      updated_first_page_view = PageView.find_by(visitor_digest:, pathname: "/")
      second_page_view = PageView.find_by(visitor_digest:, pathname: "/about")

      refute updated_first_page_view.bounced
      assert second_page_view.bounced
    end
  end

  test "all pageviews in session are marked as not bounced" do
    site = sites(:my_blog)
    property_id = site.property_id

    req_1 = FakeRequest.new("19.20.21.22", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    pr_1 = PixelRequest.from_incoming(req_1, { pid: property_id, p: "/page1", h: "blog.net" })
    pr_1.process!
    visitor_digest = pr_1.send(:visitor_digest)

    travel_to 5.minutes.from_now do
      req_2 = FakeRequest.new("19.20.21.22", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      pr_2 = PixelRequest.from_incoming(req_2, { pid: property_id, p: "/page2", h: "blog.net" })
      pr_2.process!
    end

    travel_to 10.minutes.from_now do
      req_3 = FakeRequest.new("19.20.21.22", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      pr_3 = PixelRequest.from_incoming(req_3, { pid: property_id, p: "/page3", h: "blog.net" })
      pr_3.process!
    end

    page_view_1 = PageView.find_by(visitor_digest:, pathname: "/page1")
    page_view_2 = PageView.find_by(visitor_digest:, pathname: "/page2")
    page_view_3 = PageView.find_by(visitor_digest:, pathname: "/page3")

    refute page_view_1.bounced
    refute page_view_2.bounced
    assert page_view_3.bounced
  end

  test "last pageview in session retains bounced true" do
    site = sites(:my_blog)
    property_id = site.property_id

    req_1 = FakeRequest.new("20.21.22.23", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    pr_1 = PixelRequest.from_incoming(req_1, { pid: property_id, p: "/", h: "blog.net" })
    pr_1.process!
    visitor_digest = pr_1.send(:visitor_digest)

    travel_to 5.minutes.from_now do
      req_2 = FakeRequest.new("20.21.22.23", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      pr_2 = PixelRequest.from_incoming(req_2, { pid: property_id, p: "/about", h: "blog.net" })
      pr_2.process!
    end

    travel_to 40.minutes.from_now do
      req_3 = FakeRequest.new("20.21.22.23", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      pr_3 = PixelRequest.from_incoming(req_3, { pid: property_id, p: "/contact", h: "blog.net" })
      pr_3.process!
    end

    page_view_1 = PageView.find_by(visitor_digest:, pathname: "/")
    page_view_2 = PageView.find_by(visitor_digest:, pathname: "/about")
    page_view_3 = PageView.find_by(visitor_digest:, pathname: "/contact")

    refute page_view_1.bounced
    assert page_view_2.bounced
    assert page_view_3.bounced
  end

  test "pageview outside session window does not update previous session bounce status" do
    site = sites(:my_blog)
    property_id = site.property_id

    req_1 = FakeRequest.new("21.22.23.24", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    pr_1 = PixelRequest.from_incoming(req_1, { pid: property_id, p: "/", h: "blog.net" })
    pr_1.process!
    visitor_digest = pr_1.send(:visitor_digest)

    first_page_view = PageView.find_by(visitor_digest:, pathname: "/")
    assert first_page_view.bounced

    travel_to 35.minutes.from_now do
      req_2 = FakeRequest.new("21.22.23.24", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      pr_2 = PixelRequest.from_incoming(req_2, { pid: property_id, p: "/about", h: "blog.net" })
      pr_2.process!

      updated_first_page_view = PageView.find_by(visitor_digest:, pathname: "/")
      assert updated_first_page_view.bounced
    end
  end

  test "session boundary exactly at timeout threshold creates new session" do
    site = sites(:my_blog)
    property_id = site.property_id

    req_1 = FakeRequest.new("22.23.24.25", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    pr_1 = PixelRequest.from_incoming(req_1, { pid: property_id, p: "/", h: "blog.net" })
    pr_1.process!

    travel_to 30.minutes.from_now + 1.second do
      req_2 = FakeRequest.new("22.23.24.25", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      pr_2 = PixelRequest.from_incoming(req_2, { pid: property_id, p: "/about", h: "blog.net" })
      pr_2.process!

      assert pr_2.instance_variable_get(:@new_session)
    end
  end

  test "different sites with different timeouts work independently" do
    site_1 = Site.create!(name: "Site One Short", salt: "placeholder1", session_timeout_minutes: 10)
    site_2 = Site.create!(name: "Site Two Long", salt: "placeholder2", session_timeout_minutes: 60)
    SiteCache.clear

    req_1 = FakeRequest.new("123.124.125.126", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    pr_1 = PixelRequest.from_incoming(req_1, { pid: site_1.property_id, p: "/", h: "short.net" })
    pr_1.process!

    req_2 = FakeRequest.new("124.125.126.127", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    pr_2 = PixelRequest.from_incoming(req_2, { pid: site_2.property_id, p: "/", h: "long.net" })
    pr_2.process!

    travel_to 15.minutes.from_now do
      req_3 = FakeRequest.new("123.124.125.126", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      pr_3 = PixelRequest.from_incoming(req_3, { pid: site_1.property_id, p: "/about", h: "short.net" })
      pr_3.process!

      req_4 = FakeRequest.new("124.125.126.127", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      pr_4 = PixelRequest.from_incoming(req_4, { pid: site_2.property_id, p: "/about", h: "long.net" })
      pr_4.process!

      assert pr_3.instance_variable_get(:@new_session)
      refute pr_4.instance_variable_get(:@new_session)
    end
  end

  test "new pageview is created with bounced true and duration nil" do
    site = sites(:my_blog)
    req = FakeRequest.new("25.26.27.28", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    pr = PixelRequest.from_incoming(req, { pid: site.property_id, p: "/", h: "blog.net" })
    pr.process!

    page_view = PageView.find_by(visitor_digest: pr.send(:visitor_digest))

    assert page_view.bounced
    assert_nil page_view.duration
  end

  test "visitor_attributes includes salt_version from property" do
    site = sites(:my_blog)
    req = FakeRequest.new("26.27.28.29", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    pr = PixelRequest.from_incoming(req, { pid: site.property_id, p: "/", h: "blog.net" })
    pr.process!

    visitor = Visitor.find_by(digest: pr.send(:visitor_digest))

    assert_not_nil visitor
    assert_equal site.salt_version, visitor.salt_version
  end
end
