# frozen_string_literal: true

require "test_helper"

class SiteCardComponentTest < ViewComponent::TestCase
  test "renders site name" do
    site = Site.create!(name: "My Test Site")

    render_inline(SiteCardComponent.new(site: site))

    assert_text "My Test Site"
  end

  test "renders property id" do
    site = Site.create!(name: "My Test Site")

    render_inline(SiteCardComponent.new(site: site))

    assert_text site.property_id
  end

  test "renders creation date" do
    site = Site.create!(name: "My Test Site")

    render_inline(SiteCardComponent.new(site: site))

    assert_text "Created"
  end

  test "renders without stats when stats is nil" do
    site = Site.create!(name: "My Test Site")

    render_inline(SiteCardComponent.new(site: site, stats: nil))

    assert_text "My Test Site"
    assert_no_text "No data available"
  end

  test "renders stats section when stats provided" do
    site = Site.create!(name: "My Test Site")
    stats = {
      site: site,
      granularity: :daily,
      period_days: 7,
      avg_daily_pageviews: 100.5,
      avg_daily_sessions: 50.2,
      avg_daily_duration: 45.3,
      top_page_by_sessions: nil,
      top_page_by_duration: nil
    }

    render_inline(SiteCardComponent.new(site: site, stats: stats))

    assert_text "Pageviews"
    assert_text "Sessions"
    assert_text "Avg Duration"
    assert_text "100.5"
    assert_text "50.2"
    assert_text "45s"
  end

  test "renders granularity label for daily stats" do
    site = Site.create!(name: "My Test Site")
    stats = {
      site: site,
      granularity: :daily,
      period_days: 7,
      avg_daily_pageviews: 100.0,
      avg_daily_sessions: 50.0,
      avg_daily_duration: 45.0,
      top_page_by_sessions: nil,
      top_page_by_duration: nil
    }

    render_inline(SiteCardComponent.new(site: site, stats: stats))

    assert_text "Last 7 days"
  end

  test "renders granularity label for hourly stats" do
    site = Site.create!(name: "My Test Site")
    stats = {
      site: site,
      granularity: :hourly,
      period_days: 1,
      avg_daily_pageviews: 100.0,
      avg_daily_sessions: 50.0,
      avg_daily_duration: 45.0,
      top_page_by_sessions: nil,
      top_page_by_duration: nil
    }

    render_inline(SiteCardComponent.new(site: site, stats: stats))

    assert_text "Last 24 hours"
  end

  test "renders granularity label for weekly stats" do
    site = Site.create!(name: "My Test Site")
    stats = {
      site: site,
      granularity: :weekly,
      period_days: 28,
      avg_daily_pageviews: 100.0,
      avg_daily_sessions: 50.0,
      avg_daily_duration: 45.0,
      top_page_by_sessions: nil,
      top_page_by_duration: nil
    }

    render_inline(SiteCardComponent.new(site: site, stats: stats))

    assert_text "Last 28 days"
  end

  test "shows no data available when stats are zero" do
    site = Site.create!(name: "My Test Site")
    stats = {
      site: site,
      granularity: :daily,
      period_days: 0,
      avg_daily_pageviews: 0.0,
      avg_daily_sessions: 0.0,
      avg_daily_duration: nil,
      top_page_by_sessions: nil,
      top_page_by_duration: nil
    }

    render_inline(SiteCardComponent.new(site: site, stats: stats))

    assert_text "No data available"
  end

  test "renders N/A for duration when nil" do
    site = Site.create!(name: "My Test Site")
    stats = {
      site: site,
      granularity: :daily,
      period_days: 7,
      avg_daily_pageviews: 100.0,
      avg_daily_sessions: 50.0,
      avg_daily_duration: nil,
      top_page_by_sessions: nil,
      top_page_by_duration: nil
    }

    render_inline(SiteCardComponent.new(site: site, stats: stats))

    assert_text "N/A"
  end

  test "renders settings link" do
    site = Site.create!(name: "My Test Site")

    render_inline(SiteCardComponent.new(site: site))

    assert_link href: "/sites/#{site.id}/edit"
  end

  test "renders instructions link" do
    site = Site.create!(name: "My Test Site")

    render_inline(SiteCardComponent.new(site: site))

    assert_link href: "/sites/#{site.id}/instructions"
  end

  test "rounds pageviews and sessions values" do
    site = Site.create!(name: "My Test Site")
    stats = {
      site: site,
      granularity: :daily,
      period_days: 7,
      avg_daily_pageviews: 100.567,
      avg_daily_sessions: 50.234,
      avg_daily_duration: 45.8,
      top_page_by_sessions: nil,
      top_page_by_duration: nil
    }

    render_inline(SiteCardComponent.new(site: site, stats: stats))

    assert_text "100.6"
    assert_text "50.2"
    assert_text "46s"
  end

  test "handles unknown granularity" do
    site = Site.create!(name: "My Test Site")
    stats = {
      site: site,
      granularity: :unknown,
      period_days: 7,
      avg_daily_pageviews: 100.0,
      avg_daily_sessions: 50.0,
      avg_daily_duration: 45.0,
      top_page_by_sessions: nil,
      top_page_by_duration: nil
    }

    render_inline(SiteCardComponent.new(site: site, stats: stats))

    assert_text "My Test Site"
  end
end
