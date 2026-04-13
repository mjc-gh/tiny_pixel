# frozen_string_literal: true

require "test_helper"

class ReferrerParserTest < ActiveSupport::TestCase
  test "parses valid HTTPS referrer URL" do
    result = ReferrerParser.parse("https://google.com/search?q=ruby")
    assert_equal "google.com", result[:hostname]
    assert_equal "/search", result[:pathname]
  end

  test "parses URL with www prefix" do
    result = ReferrerParser.parse("https://www.google.com/path")
    assert_equal "google.com", result[:hostname]
    assert_equal "/path", result[:pathname]
  end

  test "handles URL with no pathname" do
    result = ReferrerParser.parse("https://example.com")
    assert_equal "example.com", result[:hostname]
    assert_equal "/", result[:pathname]
  end

  test "handles empty referrer" do
    result = ReferrerParser.parse("")
    assert_nil result[:hostname]
    assert_nil result[:pathname]
  end

  test "handles nil referrer" do
    result = ReferrerParser.parse(nil)
    assert_nil result[:hostname]
    assert_nil result[:pathname]
  end

  test "handles malformed URL" do
    result = ReferrerParser.parse("not-a-url")
    assert_nil result[:hostname]
    assert_nil result[:pathname]
  end

  test "handles URL with port" do
    result = ReferrerParser.parse("https://example.com:8080/path")
    assert_equal "example.com", result[:hostname]
    assert_equal "/path", result[:pathname]
  end

  test "handles URL with fragment" do
    result = ReferrerParser.parse("https://example.com/path#section")
    assert_equal "example.com", result[:hostname]
    assert_equal "/path", result[:pathname]
  end

  test "lowercases hostname" do
    result = ReferrerParser.parse("https://EXAMPLE.COM/path")
    assert_equal "example.com", result[:hostname]
  end

  test "removes www from uppercase domain" do
    result = ReferrerParser.parse("https://WWW.EXAMPLE.COM/path")
    assert_equal "example.com", result[:hostname]
  end

  test "handles URL with multiple path segments" do
    result = ReferrerParser.parse("https://example.com/path/to/page")
    assert_equal "example.com", result[:hostname]
    assert_equal "/path/to/page", result[:pathname]
  end

  test "handles URL with query string" do
    result = ReferrerParser.parse("https://example.com/search?q=test&filter=active")
    assert_equal "example.com", result[:hostname]
    assert_equal "/search", result[:pathname]
  end

  test "handles HTTP referrer" do
    result = ReferrerParser.parse("http://example.com/page")
    assert_equal "example.com", result[:hostname]
    assert_equal "/page", result[:pathname]
  end

  test "handles whitespace-padded referrer" do
    result = ReferrerParser.parse("  https://example.com/page  ")
    assert_equal "example.com", result[:hostname]
    assert_equal "/page", result[:pathname]
  end

  test "class method delegates to instance" do
    result = ReferrerParser.parse("https://example.com/test")
    assert_equal "example.com", result[:hostname]
    assert_equal "/test", result[:pathname]
  end

  test "handles invalid URI with invalid characters" do
    result = ReferrerParser.parse("ht!tp://exa mple.com/page")
    assert_nil result[:hostname]
    assert_nil result[:pathname]
  end
end
