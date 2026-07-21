# frozen_string_literal: true

require "test_helper"

class SitesControllerTest < ActionDispatch::IntegrationTest
  test "redirects unauthenticated users to login" do
    get sites_url

    assert_redirected_to login_path
  end

  test "authenticated users can access index" do
    login(users(:alice))

    get sites_url

    assert_response :success
  end

  test "displays user sites" do
    login(users(:alice))

    get sites_url

    assert_select "h2", text: sites(:my_blog).name
    assert_select "h2", text: sites(:tech_blog).name
  end

  test "does not display other users sites" do
    login(users(:bob))

    get sites_url

    assert_select "h2", text: sites(:my_blog).name
    assert_select "h2", text: sites(:tech_blog).name, count: 0
  end

  test "redirects to onboarding when user has no sites" do
    user = User.create!(email: "newuser@example.com", password: "password12345", password_confirmation: "password12345")
    login(user, password: "password12345")

    get sites_url

    assert_redirected_to new_onboarding_site_path
  end

  test "authenticated users can access show" do
    login(users(:alice))

    get site_url(sites(:my_blog))

    assert_response :success
  end

  test "show displays site name" do
    login(users(:alice))

    get site_url(sites(:my_blog))

    assert_select "h1", text: sites(:my_blog).name
  end

  test "show displays turbo frames for stats sections" do
    login(users(:alice))

    get site_url(sites(:my_blog))

    assert_select "turbo-frame#page_views_stats"
    assert_select "turbo-frame#visitors_stats"
    assert_select "turbo-frame#avg_duration_stats"
    assert_select "turbo-frame#bounce_rate_stats"
  end

  test "show displays interval selector" do
    login(users(:alice))

    get site_url(sites(:my_blog))

    assert_select "input[type='radio'][name='interval']", count: 3
  end

  test "show accepts interval parameter" do
    login(users(:alice))

    get site_url(sites(:my_blog), interval: "hourly")

    assert_response :success
  end

  test "show defaults to daily interval" do
    login(users(:alice))

    get site_url(sites(:my_blog))

    assert_select "input[type='radio'][name='interval'][value='daily'][checked]"
  end

  test "show returns 404 for unauthorized site" do
    login(users(:bob))

    get site_url(sites(:tech_blog))

    assert_response :not_found
  end

  test "show allows bob to access my_blog where he is a member" do
    login(users(:bob))

    get site_url(sites(:my_blog))

    assert_response :success
  end

  test "show does not display UTM widgets when no UTM data exists" do
    login(users(:alice))

    get site_url(sites(:tech_blog))

    assert_select "turbo-frame#utm_source_stats", count: 0
    assert_select "turbo-frame#utm_medium_stats", count: 0
    assert_select "turbo-frame#utm_campaign_stats", count: 0
  end

  test "show displays UTM widgets when UTM data exists" do
    login(users(:alice))
    site = sites(:tech_blog)
    create_daily_stat_with_dimension(
      site,
      dimension_type: "utm_source",
      dimension_value: "google",
      pageviews: 100,
      sessions: 50
    )

    get site_url(site)

    assert_select "turbo-frame#utm_source_stats"
    assert_select "turbo-frame#utm_medium_stats"
    assert_select "turbo-frame#utm_campaign_stats"
  end

  test "new redirects unauthenticated users to login" do
    get new_site_url

    assert_redirected_to login_path
  end

  test "authenticated users can access new" do
    login(users(:alice))

    get new_site_url

    assert_response :success
  end

  test "new displays the site form fields" do
    login(users(:alice))

    get new_site_url

    assert_select "input#site_name"
    assert_select "select#site_salt_duration"
    assert_select "input#site_display_hostname[type='checkbox']"
  end

  test "create redirects unauthenticated users to login" do
    post sites_url, params: { site: { name: "New Site" } }

    assert_redirected_to login_path
  end

  test "valid create saves site and creates admin membership" do
    login(users(:alice))
    original_count = Site.count

    post sites_url, params: { site: { name: "New Site", salt_duration: "daily", display_hostname: true } }

    assert_equal original_count + 1, Site.count
    assert users(:alice).sites.exists?(name: "New Site")
  end

  test "valid create redirects to site show page" do
    login(users(:alice))

    post sites_url, params: { site: { name: "New Site", salt_duration: "daily", display_hostname: true } }

    new_site = Site.find_by(name: "New Site")
    assert_redirected_to site_url(new_site)
  end

  test "invalid create with empty name re-renders form with errors" do
    login(users(:alice))

    post sites_url, params: { site: { name: "" } }

    assert_response :unprocessable_entity
    assert_select ".bg-danger-bg"
  end

  test "invalid create with name too long re-renders form with errors" do
    login(users(:alice))

    post sites_url, params: { site: { name: "a" * 61 } }

    assert_response :unprocessable_entity
    assert_select ".bg-danger-bg"
  end

  test "edit redirects unauthenticated users to login" do
    get edit_site_url(sites(:my_blog))

    assert_redirected_to login_path
  end

  test "authenticated users can access edit for their sites" do
    login(users(:alice))

    get edit_site_url(sites(:my_blog))

    assert_response :success
  end

  test "edit displays current site settings" do
    login(users(:alice))

    get edit_site_url(sites(:my_blog))

    assert_select "input#site_name"
    assert_select "select#site_salt_duration"
    assert_select "input#site_display_hostname[type='checkbox']"
  end

  test "edit returns 403 for members with member role" do
    login(users(:bob))

    get edit_site_url(sites(:my_blog))

    assert_response :forbidden
  end

  test "update redirects unauthenticated users to login" do
    patch site_url(sites(:my_blog)), params: { site: { salt_duration: "weekly" } }

    assert_redirected_to login_path
  end

  test "update saves valid salt_duration changes" do
    login(users(:alice))
    original_duration = sites(:my_blog).salt_duration

    patch site_url(sites(:my_blog)), params: { site: { salt_duration: "weekly" } }

    sites(:my_blog).reload
    assert_equal "weekly", sites(:my_blog).salt_duration
    assert_not_equal original_duration, sites(:my_blog).salt_duration
  end

  test "update saves valid display_hostname changes" do
    login(users(:alice))
    original_display_hostname = sites(:my_blog).display_hostname

    patch site_url(sites(:my_blog)), params: { site: { display_hostname: !original_display_hostname } }

    sites(:my_blog).reload
    assert_equal !original_display_hostname, sites(:my_blog).display_hostname
  end

  test "update returns 404 for unauthorized site" do
    login(users(:bob))

    patch site_url(sites(:tech_blog)), params: { site: { salt_duration: "monthly" } }

    assert_response :not_found
  end

  test "update returns 403 for members with member role" do
    login(users(:bob))

    patch site_url(sites(:my_blog)), params: { site: { name: "Hacked Name" } }

    assert_response :forbidden
  end

  test "update redirects to site show page on success" do
   login(users(:alice))

   patch site_url(sites(:my_blog)), params: { site: { salt_duration: "monthly" } }

   assert_redirected_to site_url(sites(:my_blog))
 end

  test "update saves valid name changes" do
    login(users(:alice))
    original_name = sites(:my_blog).name

    patch site_url(sites(:my_blog)), params: { site: { name: "Updated Blog Name" } }

    sites(:my_blog).reload
    assert_equal "Updated Blog Name", sites(:my_blog).name
    assert_not_equal original_name, sites(:my_blog).name
  end

  test "update rejects empty name" do
    login(users(:alice))

    patch site_url(sites(:my_blog)), params: { site: { name: "" } }

    assert_response :unprocessable_entity
    assert_select ".bg-danger-bg"
  end

  test "update rejects name exceeding maximum length" do
    login(users(:alice))

    patch site_url(sites(:my_blog)), params: { site: { name: "a" * 61 } }

    assert_response :unprocessable_entity
    assert_select ".bg-danger-bg"
  end

  test "index computes stats for each site" do
    login(users(:alice))

    site = sites(:my_blog)
    # Create some stats for the site
    start_date = 7.days.ago.to_date
    (0..6).each do |offset|
      date = start_date + offset.days
      DailyPageStat.create!(
        site_id: site.id,
        hostname: "example.com",
        pathname: "/page1",
        date: date,
        dimension_type: "global",
        pageviews: 100,
        sessions: 50,
        total_duration: 500.0,
        duration_count: 10
      )
    end

    get sites_url

    assert_response :success
    # Stats should be assigned to the view
    assert_not_nil assigns(:sites_stats)
    assert_equal users(:alice).sites.count, assigns(:sites_stats).count
  end

  test "index displays stats for sites in cards" do
    login(users(:alice))

    site = sites(:my_blog)
    # Create some stats for the site - make it a mid-age site
    site.update(created_at: 7.days.ago)
    start_date = 7.days.ago.to_date
    (0..6).each do |offset|
      date = start_date + offset.days
      DailyPageStat.create!(
        site_id: site.id,
        hostname: "example.com",
        pathname: "/page1",
        date: date,
        dimension_type: "global",
        pageviews: 100,
        sessions: 50,
        total_duration: 500.0,
        duration_count: 10
      )
    end

    get sites_url

    assert_response :success
    # Should display pageviews in the card
    assert_select "p", text: "Pageviews"
    assert_select "p", text: "Sessions"
  end

  test "index handles multiple sites with stats" do
    login(users(:alice))

    sites(:my_blog).update(created_at: 7.days.ago)
    sites(:tech_blog).update(created_at: 7.days.ago)

    # Create stats for both sites
    [sites(:my_blog), sites(:tech_blog)].each do |site|
      start_date = 7.days.ago.to_date
      (0..6).each do |offset|
        date = start_date + offset.days
        DailyPageStat.create!(
          site_id: site.id,
          hostname: "example.com",
          pathname: "/page1",
          date: date,
          dimension_type: "global",
          pageviews: 100,
          sessions: 50,
          total_duration: 500.0,
          duration_count: 10
        )
      end
    end

    get sites_url

    assert_response :success
    assert_equal 2, assigns(:sites_stats).count
  end
end
