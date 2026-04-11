# frozen_string_literal: true

require "test_helper"

class DateRangeSelectorComponentTest < ViewComponent::TestCase
  def test_renders_two_date_inputs
    site = sites(:my_blog)
    render_inline(DateRangeSelectorComponent.new(start_date: nil, end_date: nil, site: site))

    assert_selector "input[type='date']", count: 2
  end

  def test_renders_start_date_input
    site = sites(:my_blog)
    render_inline(DateRangeSelectorComponent.new(start_date: nil, end_date: nil, site: site))

    assert_selector "input[name='start_date'][type='date']"
  end

  def test_renders_end_date_input
    site = sites(:my_blog)
    render_inline(DateRangeSelectorComponent.new(start_date: nil, end_date: nil, site: site))

    assert_selector "input[name='end_date'][type='date']"
  end

  def test_populates_start_date_value
    site = sites(:my_blog)
    start_date = Date.new(2024, 1, 15)

    render_inline(DateRangeSelectorComponent.new(start_date: start_date, end_date: nil, site: site))

    assert_selector "input[name='start_date'][value='2024-01-15']"
  end

  def test_populates_end_date_value
    site = sites(:my_blog)
    end_date = Date.new(2024, 1, 31)

    render_inline(DateRangeSelectorComponent.new(start_date: nil, end_date: end_date, site: site))

    assert_selector "input[name='end_date'][value='2024-01-31']"
  end

  def test_populates_both_date_values
    site = sites(:my_blog)
    start_date = Date.new(2024, 1, 15)
    end_date = Date.new(2024, 1, 31)

    render_inline(DateRangeSelectorComponent.new(start_date: start_date, end_date: end_date, site: site))

    assert_selector "input[name='start_date'][value='2024-01-15']"
    assert_selector "input[name='end_date'][value='2024-01-31']"
  end

  def test_renders_to_label
    site = sites(:my_blog)
    render_inline(DateRangeSelectorComponent.new(start_date: nil, end_date: nil, site: site))

    assert_selector "span", text: "to"
  end

  def test_has_stimulus_targets_for_date_inputs
    site = sites(:my_blog)
    render_inline(DateRangeSelectorComponent.new(start_date: nil, end_date: nil, site: site))

    assert_selector "input[data-site-dashboard-target='startDate']"
    assert_selector "input[data-site-dashboard-target='endDate']"
  end

  def test_has_change_action_for_date_inputs
    site = sites(:my_blog)
    render_inline(DateRangeSelectorComponent.new(start_date: nil, end_date: nil, site: site))

    assert_selector "input[data-action='change->site-dashboard#updateDateRange']", count: 2
  end

  def test_renders_with_nil_dates
    site = sites(:my_blog)
    render_inline(DateRangeSelectorComponent.new(start_date: nil, end_date: nil, site: site))

    assert_selector "input[type='date'][value='']"
  end
end
