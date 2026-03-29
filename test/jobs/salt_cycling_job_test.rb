# frozen_string_literal: true

require "test_helper"

class SaltCyclingJobTest < ActiveSupport::TestCase
  test "perform calls Site.cycle_stale_salts!" do
    site = sites(:my_blog)
    site.update(salt_last_cycled_at: 2.days.ago)
    old_salt = site.salt

    SaltCyclingJob.new.perform

    site.reload
    assert_not_equal old_salt, site.salt
  end

  test "perform is idempotent when run multiple times" do
    site = sites(:my_blog)
    site.update(salt_last_cycled_at: 2.days.ago)

    SaltCyclingJob.new.perform
    salt_after_first_run = site.reload.salt
    cycled_at_after_first_run = site.salt_last_cycled_at

    SaltCyclingJob.new.perform
    salt_after_second_run = site.reload.salt

    assert_equal salt_after_first_run, salt_after_second_run
    assert_equal cycled_at_after_first_run, site.salt_last_cycled_at
  end

  test "perform does not cycle sites that are not due" do
    site = sites(:my_blog)
    site.update(salt_last_cycled_at: 1.hour.ago)
    old_salt = site.salt

    SaltCyclingJob.new.perform

    site.reload
    assert_equal old_salt, site.salt
  end

  test "perform cycles sites with different durations correctly" do
    daily_site = Site.create!(name: "Daily Site", salt: "placeholder", salt_duration: :daily)
    daily_site.update(salt_last_cycled_at: 2.days.ago)
    old_daily_salt = daily_site.salt

    weekly_site = Site.create!(name: "Weekly Site", salt: "placeholder", salt_duration: :weekly)
    weekly_site.update(salt_last_cycled_at: 3.days.ago)
    old_weekly_salt = weekly_site.salt

    SaltCyclingJob.new.perform

    daily_site.reload
    weekly_site.reload

    assert_not_equal old_daily_salt, daily_site.salt
    assert_equal old_weekly_salt, weekly_site.salt
  end
end
