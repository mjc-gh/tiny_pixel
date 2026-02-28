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

  test "::perform_periodic_operations calls cycle_stale_salts!" do
    old_site = sites(:my_blog)
    old_site.update(salt_last_cycled_at: 2.days.ago)
    old_salt = old_site.salt

    Site.perform_periodic_operations

    old_site.reload
    assert_not_equal old_salt, old_site.salt
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
    site1 = Site.create!(
      name: "Site 1",
      salt: SecureRandom.urlsafe_base64(32)
    )

    site2 = Site.create!(
      name: "Site 2",
      salt: SecureRandom.urlsafe_base64(32)
    )

    assert_not_equal site1.property_id, site2.property_id
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

  test "salt_duration enum is set to daily" do
    site = sites(:my_blog)
    assert_equal "daily", site.salt_duration
  end
end
