# frozen_string_literal: true

require "test_helper"

class SiteTest < ActiveSupport::TestCase
  test "#cycle_salt" do
    s = sites(:my_blog)

    assert_changes(-> { s.salt }) { s.cycle_salt }
    assert_changes(-> { s.salt_last_cycled_at }) { s.cycle_salt }
    assert_changes(-> { s.salt_version }, to: 3) { s.cycle_salt }
  end

  test "::cycle_stale_salts!" do
  end
end
