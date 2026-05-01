# frozen_string_literal: true

require "test_helper"

class SiteTest < ActiveSupport::TestCase
  test "#cycle_salt" do
    s = sites(:my_blog)
    initial_version = s.salt_version
    initial_salt = s.salt
    initial_cycled_at = s.salt_last_cycled_at

    s.cycle_salt

    assert_not_equal initial_salt, s.salt
    assert_not_equal initial_cycled_at, s.salt_last_cycled_at
    assert_equal initial_version + 1, s.salt_version
  end

  test "#cycle_salt generates valid base64 string" do
    s = sites(:my_blog)
    s.cycle_salt

    assert_match(/\A[A-Za-z0-9\-_=]+\z/, s.salt)
    assert s.salt.length > 0
  end

  test "::cycle_stale_salts!" do
    # Create a site that needs salt cycling (last cycled > 1 day ago)
    old_site = sites(:my_blog)
    old_site.update(salt_last_cycled_at: 2.days.ago)

    # Create a site that doesn't need cycling (recently cycled)
    new_site = Site.create!(
      name: "Recent Site",
      salt: SecureRandom.urlsafe_base64(32),
      salt_last_cycled_at: 1.hour.ago
    )

    old_salt = old_site.salt
    new_salt = new_site.salt

    Site.send(:cycle_stale_salts!)

    old_site.reload
    new_site.reload

    # Old site should have new salt
    assert_not_equal old_salt, old_site.salt
    assert_not_nil old_site.salt_last_cycled_at

    # New site should retain original salt
    assert_equal new_salt, new_site.salt
  end

  test "need_to_cycle_salt scope returns only stale sites" do
    # Create a site with recent salt cycle (within last day)
    recent_site = Site.create!(
      name: "Recent Site",
      salt: SecureRandom.urlsafe_base64(32)
    )

    # Create a site that needs cycling and then set its last_cycled_at to past
    stale_site = Site.create!(
      name: "Stale Site",
      salt: SecureRandom.urlsafe_base64(32)
    )
    stale_site.update(salt_last_cycled_at: 2.days.ago)

    # Update fixture site to be stale
    sites(:my_blog).update(salt_last_cycled_at: 3.days.ago)

    stale_sites = Site.need_to_cycle_salt

    assert_includes stale_sites, sites(:my_blog)
    assert_includes stale_sites, stale_site
    assert_not_includes stale_sites, recent_site
  end

  test "before_validation sets property_id on create" do
    site = Site.new(
      name: "New Site",
      salt: SecureRandom.urlsafe_base64(32)
    )

    assert_nil site.property_id
    site.validate
    assert_not_nil site.property_id
  end

  test "property_id has correct length" do
    site = Site.create!(
      name: "Property Test Site",
      salt: SecureRandom.urlsafe_base64(32)
    )

    assert_equal 8, site.property_id.length
  end

  test "property_id contains only uppercase letters" do
    site = Site.create!(
      name: "Charset Test Site",
      salt: SecureRandom.urlsafe_base64(32)
    )

    assert_match(/\A[A-Z]{8}\z/, site.property_id)
  end

  test "property_id is unique for different sites" do
    site_1 = Site.create!(
      name: "Site 1",
      salt: SecureRandom.urlsafe_base64(32)
    )

    site_2 = Site.create!(
      name: "Site 2",
      salt: SecureRandom.urlsafe_base64(32)
    )

    assert_not_equal site_1.property_id, site_2.property_id
  end

  test "before_validation does not reset property_id on update" do
    site = sites(:my_blog)
    original_property_id = site.property_id

    site.update(name: "Updated Name")

    assert_equal original_property_id, site.property_id
  end

  test "before_create initializes salt with cycle_salt" do
    site = Site.create!(
      name: "Salt Init Test",
      salt: "initial_placeholder"
    )

    # Verify salt was set by cycle_salt (not the placeholder)
    assert_not_equal "initial_placeholder", site.salt
    assert_match(/\A[A-Za-z0-9\-_=]+\z/, site.salt)
    assert site.salt.length > 0
  end

  test "before_create sets salt_version to 1" do
    site = Site.create!(
      name: "Salt Version Test",
      salt: "placeholder"
    )

    assert_equal 1, site.salt_version
  end

  test "need_to_cycle_salt scope includes daily sites after 1 day" do
    site = Site.create!(name: "Daily Site", salt: "placeholder", salt_duration: :daily)
    site.update(salt_last_cycled_at: 2.days.ago)

    assert_includes Site.need_to_cycle_salt, site
  end

  test "need_to_cycle_salt scope excludes daily sites within 1 day" do
    site = Site.create!(name: "Daily Recent Site", salt: "placeholder", salt_duration: :daily)
    site.update(salt_last_cycled_at: 12.hours.ago)

    assert_not_includes Site.need_to_cycle_salt, site
  end

  test "need_to_cycle_salt scope includes weekly sites after 1 week" do
    site = Site.create!(name: "Weekly Site", salt: "placeholder", salt_duration: :weekly)
    site.update(salt_last_cycled_at: 8.days.ago)

    assert_includes Site.need_to_cycle_salt, site
  end

  test "need_to_cycle_salt scope excludes weekly sites within 1 week" do
    site = Site.create!(name: "Weekly Recent Site", salt: "placeholder", salt_duration: :weekly)
    site.update(salt_last_cycled_at: 3.days.ago)

    assert_not_includes Site.need_to_cycle_salt, site
  end

  test "need_to_cycle_salt scope includes monthly sites after 1 month" do
    site = Site.create!(name: "Monthly Site", salt: "placeholder", salt_duration: :monthly)
    site.update(salt_last_cycled_at: 32.days.ago)

    assert_includes Site.need_to_cycle_salt, site
  end

  test "need_to_cycle_salt scope excludes monthly sites within 1 month" do
    site = Site.create!(name: "Monthly Recent Site", salt: "placeholder", salt_duration: :monthly)
    site.update(salt_last_cycled_at: 15.days.ago)

    assert_not_includes Site.need_to_cycle_salt, site
  end


  test "session_timeout_minutes defaults to 30" do
    site = Site.create!(name: "Timeout Test", salt: "placeholder")

    assert_equal 30, site.session_timeout_minutes
  end

  test "#session_timeout returns duration in minutes" do
    site = sites(:my_blog)
    site.session_timeout_minutes = 45

    assert_equal 45.minutes, site.session_timeout
    assert_kind_of ActiveSupport::Duration, site.session_timeout
  end

  test "#stats_retention_period returns correct ActiveSupport::Duration" do
    site = sites(:my_blog)
    site.stats_retention_duration = 12
    site.stats_retention_unit = :months

    assert_equal 12.months, site.stats_retention_period
    assert_kind_of ActiveSupport::Duration, site.stats_retention_period
  end

  test "#stats_retention_period works with all retention units" do
    site = sites(:my_blog)

    site.stats_retention_unit = :days
    site.stats_retention_duration = 7
    assert_equal 7.days, site.stats_retention_period

    site.stats_retention_unit = :weeks
    site.stats_retention_duration = 4
    assert_equal 4.weeks, site.stats_retention_period

    site.stats_retention_unit = :months
    site.stats_retention_duration = 6
    assert_equal 6.months, site.stats_retention_period

    site.stats_retention_unit = :years
    site.stats_retention_duration = 2
    assert_equal 2.years, site.stats_retention_period
  end

  test "#stats_retention_cutoff returns time in the past" do
    site = sites(:my_blog)
    site.stats_retention_duration = 30
    site.stats_retention_unit = :days

    now = Time.current
    cutoff = site.stats_retention_cutoff

    assert cutoff < now
    # The cutoff should be approximately 30 days ago (allow some tolerance)
    assert_in_delta cutoff, 30.days.ago, 5.seconds
  end

  test "stats_retention_duration must be positive" do
    site = sites(:my_blog)
    site.stats_retention_duration = 0

    assert_not site.valid?
  end

  test "stats_retention_duration negative value is invalid" do
    site = sites(:my_blog)
    site.stats_retention_duration = -5

    assert_not site.valid?
  end

  test "stats_retention_unit enum values are correct" do
    assert_equal({ "days" => 0, "weeks" => 1, "months" => 2, "years" => 3 }, Site.stats_retention_units)
  end

  test "stats_retention_unit defaults to months (2)" do
    site = Site.create!(name: "Retention Test", salt: "placeholder")

    assert site.months?
  end

  test "stats_retention_duration defaults to 12" do
    site = Site.create!(name: "Retention Test", salt: "placeholder")

    assert_equal 12, site.stats_retention_duration
  end
end
