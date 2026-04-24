# frozen_string_literal: true

require "test_helper"

class IntervalSelectorComponentTest < ViewComponent::TestCase
  test "renders select element" do
    site = sites(:my_blog)

    render_inline(IntervalSelectorComponent.new(current_interval: "daily", site: site))

    assert_selector "select#interval"
  end

  test "renders all interval options" do
    site = sites(:my_blog)

    render_inline(IntervalSelectorComponent.new(current_interval: "daily", site: site))

    assert_selector "option", text: "Hourly"
    assert_selector "option", text: "Daily"
    assert_selector "option", text: "Weekly"
  end

  test "marks current interval as selected" do
    site = sites(:my_blog)

    render_inline(IntervalSelectorComponent.new(current_interval: "hourly", site: site))

    assert_selector "option[selected]", text: "Hourly"
  end

  test "daily selected by default" do
    site = sites(:my_blog)

    render_inline(IntervalSelectorComponent.new(current_interval: "daily", site: site))

    assert_selector "option[selected]", text: "Daily"
  end

  test "weekly interval selection" do
    site = sites(:my_blog)

    render_inline(IntervalSelectorComponent.new(current_interval: "weekly", site: site))

    assert_selector "option[selected]", text: "Weekly"
  end

  test "renders label" do
    site = sites(:my_blog)

    render_inline(IntervalSelectorComponent.new(current_interval: "daily", site: site))

    assert_selector "label", text: "Interval:"
  end
end
