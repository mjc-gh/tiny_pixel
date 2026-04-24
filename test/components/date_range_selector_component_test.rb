# frozen_string_literal: true

require "test_helper"

class DateRangeSelectorComponentTest < ViewComponent::TestCase
  test "renders two date inputs" do
    site = sites(:my_blog)
    render_inline(DateRangeSelectorComponent.new(start_date: nil, end_date: nil, site: site))

    assert_selector "input[type='date']", count: 2
  end

  test "renders start date input" do
    site = sites(:my_blog)
    render_inline(DateRangeSelectorComponent.new(start_date: nil, end_date: nil, site: site))

    assert_selector "input[name='start_date'][type='date']"
  end

  test "renders end date input" do
    site = sites(:my_blog)
    render_inline(DateRangeSelectorComponent.new(start_date: nil, end_date: nil, site: site))

    assert_selector "input[name='end_date'][type='date']"
  end

  test "populates start date value" do
    site = sites(:my_blog)
    start_date = Date.new(2024, 1, 15)

    render_inline(DateRangeSelectorComponent.new(start_date: start_date, end_date: nil, site: site))

    assert_selector "input[name='start_date'][value='2024-01-15']"
  end

  test "populates end date value" do
    site = sites(:my_blog)
    end_date = Date.new(2024, 1, 31)

    render_inline(DateRangeSelectorComponent.new(start_date: nil, end_date: end_date, site: site))

    assert_selector "input[name='end_date'][value='2024-01-31']"
  end

  test "populates both date values" do
    site = sites(:my_blog)
    start_date = Date.new(2024, 1, 15)
    end_date = Date.new(2024, 1, 31)

    render_inline(DateRangeSelectorComponent.new(start_date: start_date, end_date: end_date, site: site))

    assert_selector "input[name='start_date'][value='2024-01-15']"
    assert_selector "input[name='end_date'][value='2024-01-31']"
  end

  test "renders to label" do
    site = sites(:my_blog)
    render_inline(DateRangeSelectorComponent.new(start_date: nil, end_date: nil, site: site))

    assert_selector "span", text: "to"
  end

  test "has stimulus targets for date inputs" do
    site = sites(:my_blog)
    render_inline(DateRangeSelectorComponent.new(start_date: nil, end_date: nil, site: site))

    assert_selector "input[data-site-dashboard-target='startDate']"
    assert_selector "input[data-site-dashboard-target='endDate']"
  end

  test "has change action for date inputs" do
    site = sites(:my_blog)
    render_inline(DateRangeSelectorComponent.new(start_date: nil, end_date: nil, site: site))

    assert_selector "input[data-action='change->site-dashboard#updateDateRange']", count: 2
  end

  test "renders with nil dates" do
    site = sites(:my_blog)
    render_inline(DateRangeSelectorComponent.new(start_date: nil, end_date: nil, site: site))

    assert_selector "input[type='date'][value='']"
  end
end
