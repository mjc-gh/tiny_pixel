# frozen_string_literal: true

module SharedStatTests
  extend ActiveSupport::Concern

  included do
    test "avg_duration returns nil when duration_count is zero" do
      stat = stat_class.new(total_duration: 0, duration_count: 0)

      assert_nil stat.avg_duration
    end

    test "avg_duration calculates average correctly" do
      stat = stat_class.new(total_duration: 300, duration_count: 10)

      assert_equal 30.0, stat.avg_duration
    end

    test "bounce_rate returns nil when pageviews is zero" do
      stat = stat_class.new(bounced_count: 0, pageviews: 0)

      assert_nil stat.bounce_rate
    end

    test "bounce_rate calculates percentage correctly" do
      stat = stat_class.new(bounced_count: 25, pageviews: 100)

      assert_equal 25.0, stat.bounce_rate
    end

    test "for_site scope filters by site_id" do
      site = sites(:my_blog)
      create_stat(site, pathname: "/test")

      assert_equal 1, stat_class.for_site(site.id).count
      assert_equal 0, stat_class.for_site(999).count
    end

    test "for_hostname scope filters by hostname" do
      site = sites(:my_blog)
      create_stat(site, pathname: "/test")

      assert_equal 1, stat_class.for_hostname("example.com").count
      assert_equal 0, stat_class.for_hostname("other.com").count
    end

    test "for_pathname scope filters by pathname" do
      site = sites(:my_blog)
      create_stat(site, pathname: "/test")

      assert_equal 1, stat_class.for_pathname("/test").count
      assert_equal 0, stat_class.for_pathname("/other").count
    end

    test "ordered_by_pageviews orders descending" do
      site = sites(:my_blog)
      create_stat(site, hostname: "a.com", pageviews: 10)
      create_stat(site, hostname: "b.com", pageviews: 50)
      create_stat(site, hostname: "c.com", pageviews: 25)

      stats = stat_class.ordered_by_pageviews

      assert_equal [50, 25, 10], stats.pluck(:pageviews)
    end

    test "global scope filters by dimension_type = 'global'" do
      site = sites(:my_blog)
      create_stat(site, pathname: "/test", dimension_type: "global")
      create_stat(site, pathname: "/test2", dimension_type: "country", dimension_value: "US")

      assert_equal 1, stat_class.global.count
      assert_equal "global", stat_class.global.first.dimension_type
    end

    test "for_dimension scope filters by specific dimension type and value" do
      site = sites(:my_blog)
      create_stat(site, pathname: "/test", dimension_type: "country", dimension_value: "US")
      create_stat(site, pathname: "/test2", dimension_type: "country", dimension_value: "GB")

      assert_equal 1, stat_class.for_dimension("country", "US").count
      result = stat_class.for_dimension("country", "US").first
      assert_equal "country", result.dimension_type
      assert_equal "US", result.dimension_value
    end

    test "for_dimension_type scope filters by dimension type" do
      site = sites(:my_blog)
      create_stat(site, pathname: "/test", dimension_type: "country", dimension_value: "US")
      create_stat(site, pathname: "/test2", dimension_type: "country", dimension_value: "GB")
      create_stat(site, pathname: "/test3", dimension_type: "browser", dimension_value: "chrome")

      assert_equal 2, stat_class.for_dimension_type("country").count
      assert_equal 1, stat_class.for_dimension_type("browser").count
    end
  end
end
