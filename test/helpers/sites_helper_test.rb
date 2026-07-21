# frozen_string_literal: true

require "test_helper"

class SitesHelperTest < ActionView::TestCase
  test "site_has_utm_data? returns true when UTM data exists" do
    site = sites(:tech_blog)
    create_daily_stat_with_dimension(
      site,
      dimension_type: "utm_source",
      dimension_value: "google",
      pageviews: 100,
      sessions: 50
    )

    assert site_has_utm_data?(site)
  end

  test "site_has_utm_data? returns false when no UTM data exists" do
    site = sites(:tech_blog)

    refute site_has_utm_data?(site)
  end

  test "site_has_utm_data? returns true for utm_medium data" do
    site = sites(:tech_blog)
    create_daily_stat_with_dimension(
      site,
      dimension_type: "utm_medium",
      dimension_value: "paid",
      pageviews: 100,
      sessions: 50
    )

    assert site_has_utm_data?(site)
  end

  test "site_has_utm_data? returns true for utm_campaign data" do
    site = sites(:tech_blog)
    create_daily_stat_with_dimension(
      site,
      dimension_type: "utm_campaign",
      dimension_value: "summer_sale",
      pageviews: 100,
      sessions: 50
    )

    assert site_has_utm_data?(site)
  end

  test "site_has_utm_data? returns false when non-UTM dimensions exist" do
    site = sites(:tech_blog)
    create_daily_stat_with_dimension(
      site,
      dimension_type: "country",
      dimension_value: "US",
      pageviews: 100,
      sessions: 50
    )

    refute site_has_utm_data?(site)
  end

  test "site_has_utm_data? memoizes result for same site" do
    site = sites(:tech_blog)
    create_daily_stat_with_dimension(
      site,
      dimension_type: "utm_source",
      dimension_value: "google",
      pageviews: 100,
      sessions: 50
    )

    # First call
    assert site_has_utm_data?(site)

    # Verify memoization by checking instance variable is set
    assert @site_has_utm_data.key?(site.id)
    assert @site_has_utm_data[site.id] == true
  end

  test "site_has_utm_data? handles multiple sites" do
    site1 = sites(:tech_blog)
    site2 = sites(:my_blog)

    create_daily_stat_with_dimension(
      site1,
      dimension_type: "utm_source",
      dimension_value: "google",
      pageviews: 100,
      sessions: 50
    )

    assert site_has_utm_data?(site1)
    refute site_has_utm_data?(site2)

    # Verify both are memoized
    assert @site_has_utm_data[site1.id] == true
    assert @site_has_utm_data[site2.id] == false
  end
end
