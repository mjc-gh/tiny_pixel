# frozen_string_literal: true

require "test_helper"

class PaginationComponentTest < ViewComponent::TestCase
  def create_paginated_collection(current_page:, total_pages:)
    collection = []
    collection.define_singleton_method(:current_page) { current_page }
    collection.define_singleton_method(:total_pages) { total_pages }
    collection.define_singleton_method(:previous_page) { current_page > 1 ? current_page - 1 : nil }
    collection.define_singleton_method(:next_page) { current_page < total_pages ? current_page + 1 : nil }
    collection
  end

  def test_renders_pagination_when_multiple_pages
    collection = create_paginated_collection(current_page: 1, total_pages: 5)

    render_inline(PaginationComponent.new(
      collection: collection,
      base_path: "/sites/1/page_views",
      frame_id: "page_views_stats",
      params: { interval: "daily" }
    ))

    assert_selector "nav[aria-label='Pagination']"
  end

  def test_does_not_render_for_single_page
    collection = create_paginated_collection(current_page: 1, total_pages: 1)

    render_inline(PaginationComponent.new(
      collection: collection,
      base_path: "/sites/1/page_views",
      frame_id: "page_views_stats"
    ))

    assert_no_selector "nav"
  end

  def test_renders_turbo_frame_attribute
    collection = create_paginated_collection(current_page: 2, total_pages: 5)

    render_inline(PaginationComponent.new(
      collection: collection,
      base_path: "/sites/1/page_views",
      frame_id: "page_views_stats"
    ))

    assert_selector "a[data-turbo-frame='page_views_stats']"
  end

  def test_renders_turbo_action_replace_attribute
    collection = create_paginated_collection(current_page: 2, total_pages: 5)

    render_inline(PaginationComponent.new(
      collection: collection,
      base_path: "/sites/1/page_views",
      frame_id: "page_views_stats"
    ))

    assert_selector "a[data-turbo-action='replace']"
  end

  def test_disables_previous_on_first_page
    collection = create_paginated_collection(current_page: 1, total_pages: 5)

    render_inline(PaginationComponent.new(
      collection: collection,
      base_path: "/sites/1/page_views",
      frame_id: "page_views_stats"
    ))

    assert_selector "span.cursor-not-allowed", text: "Previous"
    assert_no_selector "a", text: "Previous"
  end

  def test_disables_next_on_last_page
    collection = create_paginated_collection(current_page: 5, total_pages: 5)

    render_inline(PaginationComponent.new(
      collection: collection,
      base_path: "/sites/1/page_views",
      frame_id: "page_views_stats"
    ))

    assert_selector "span.cursor-not-allowed", text: "Next"
    assert_no_selector "a", text: "Next"
  end

  def test_renders_page_numbers
    collection = create_paginated_collection(current_page: 3, total_pages: 5)

    render_inline(PaginationComponent.new(
      collection: collection,
      base_path: "/sites/1/page_views",
      frame_id: "page_views_stats"
    ))

    (1..5).each do |page|
      assert_text page.to_s
    end
  end

  def test_highlights_current_page
    collection = create_paginated_collection(current_page: 3, total_pages: 5)

    render_inline(PaginationComponent.new(
      collection: collection,
      base_path: "/sites/1/page_views",
      frame_id: "page_views_stats"
    ))

    assert_selector "span[aria-current='page']", text: "3"
  end

  def test_includes_params_in_page_links
    collection = create_paginated_collection(current_page: 1, total_pages: 5)

    render_inline(PaginationComponent.new(
      collection: collection,
      base_path: "/sites/1/page_views",
      frame_id: "page_views_stats",
      params: { interval: "hourly" }
    ))

    assert_selector "a[href*='interval=hourly']"
  end

  def test_displays_page_info
    collection = create_paginated_collection(current_page: 2, total_pages: 5)

    render_inline(PaginationComponent.new(
      collection: collection,
      base_path: "/sites/1/page_views",
      frame_id: "page_views_stats"
    ))

    assert_text "Page"
    assert_text "2"
    assert_text "of"
    assert_text "5"
  end

  def test_renders_ellipsis_for_many_pages
    collection = create_paginated_collection(current_page: 5, total_pages: 10)

    render_inline(PaginationComponent.new(
      collection: collection,
      base_path: "/sites/1/page_views",
      frame_id: "page_views_stats"
    ))

    assert_text "..."
  end

  def test_previous_link_on_middle_page
    collection = create_paginated_collection(current_page: 3, total_pages: 5)

    render_inline(PaginationComponent.new(
      collection: collection,
      base_path: "/sites/1/page_views",
      frame_id: "page_views_stats"
    ))

    assert_selector "a[href*='page=2']"
  end

  def test_next_link_on_middle_page
    collection = create_paginated_collection(current_page: 3, total_pages: 5)

    render_inline(PaginationComponent.new(
      collection: collection,
      base_path: "/sites/1/page_views",
      frame_id: "page_views_stats"
    ))

    assert_selector "a[href*='page=4']"
  end
end
