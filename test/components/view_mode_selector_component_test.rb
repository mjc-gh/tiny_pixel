# frozen_string_literal: true

require "test_helper"

class ViewModeSelectorComponentTest < ViewComponent::TestCase
  def test_renders_select_element
    site = sites(:my_blog)

    render_inline(ViewModeSelectorComponent.new(current_view_mode: "graph", site: site, current_interval: "daily"))

    assert_selector "select#view_mode"
  end

  def test_renders_all_view_mode_options
    site = sites(:my_blog)

    render_inline(ViewModeSelectorComponent.new(current_view_mode: "graph", site: site, current_interval: "daily"))

    assert_selector "option", text: "Graph"
    assert_selector "option", text: "Table"
  end

  def test_marks_current_view_mode_as_selected
    site = sites(:my_blog)

    render_inline(ViewModeSelectorComponent.new(current_view_mode: "table", site: site, current_interval: "daily"))

    assert_selector "option[selected]", text: "Table"
  end

  def test_graph_selected_by_default
    site = sites(:my_blog)

    render_inline(ViewModeSelectorComponent.new(current_view_mode: "graph", site: site, current_interval: "daily"))

    assert_selector "option[selected]", text: "Graph"
  end

  def test_renders_label
    site = sites(:my_blog)

    render_inline(ViewModeSelectorComponent.new(current_view_mode: "graph", site: site, current_interval: "daily"))

    assert_selector "label", text: "View:"
  end

  def test_preserves_interval_in_option_values
    site = sites(:my_blog)

    render_inline(ViewModeSelectorComponent.new(current_view_mode: "graph", site: site, current_interval: "hourly"))

    table_option = page.find("option", text: "Table")
    assert_includes table_option[:value], "interval=hourly"
    assert_includes table_option[:value], "view_mode=table"
  end
end
