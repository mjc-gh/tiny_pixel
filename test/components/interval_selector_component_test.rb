# frozen_string_literal: true

require "test_helper"

class IntervalSelectorComponentTest < ViewComponent::TestCase
  def test_renders_select_element
    site = sites(:my_blog)

    render_inline(IntervalSelectorComponent.new(current_interval: "daily", site: site))

    assert_selector "select#interval"
  end

  def test_renders_all_interval_options
    site = sites(:my_blog)

    render_inline(IntervalSelectorComponent.new(current_interval: "daily", site: site))

    assert_selector "option", text: "Hourly"
    assert_selector "option", text: "Daily"
    assert_selector "option", text: "Weekly"
  end

  def test_marks_current_interval_as_selected
    site = sites(:my_blog)

    render_inline(IntervalSelectorComponent.new(current_interval: "hourly", site: site))

    assert_selector "option[selected]", text: "Hourly"
  end

  def test_daily_selected_by_default
    site = sites(:my_blog)

    render_inline(IntervalSelectorComponent.new(current_interval: "daily", site: site))

    assert_selector "option[selected]", text: "Daily"
  end

  def test_weekly_interval_selection
    site = sites(:my_blog)

    render_inline(IntervalSelectorComponent.new(current_interval: "weekly", site: site))

    assert_selector "option[selected]", text: "Weekly"
  end

  def test_renders_label
    site = sites(:my_blog)

    render_inline(IntervalSelectorComponent.new(current_interval: "daily", site: site))

    assert_selector "label", text: "Interval:"
  end
end
