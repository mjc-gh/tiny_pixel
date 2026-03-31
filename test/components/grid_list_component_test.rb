# frozen_string_literal: true

require "test_helper"

class GridListComponentTest < ViewComponent::TestCase
  def test_renders_grid_container
    render_inline(GridListComponent.new) do |grid|
      grid.with_card { "<div>Item 1</div>".html_safe }
    end

    assert_selector "div.grid"
    assert_selector "div.grid-cols-1"
    assert_selector "div.gap-6"
  end

  def test_renders_card_slots
    render_inline(GridListComponent.new) do |grid|
      grid.with_card { "<span class='test-item'>Test Content</span>".html_safe }
    end

    assert_selector "span.test-item", text: "Test Content"
  end

  def test_renders_multiple_cards
    render_inline(GridListComponent.new) do |grid|
      grid.with_card { "<div class='card'>Card 1</div>".html_safe }
      grid.with_card { "<div class='card'>Card 2</div>".html_safe }
      grid.with_card { "<div class='card'>Card 3</div>".html_safe }
    end

    assert_selector "div.card", count: 3
  end
end
