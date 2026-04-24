# frozen_string_literal: true

require "test_helper"

class PaginationComponentTest < ViewComponent::TestCase
  test "renders pagination when multiple pages" do
    collection = create_paginated_collection(current_page: 1, total_pages: 5)

    render_inline(PaginationComponent.new(
      collection: collection,
      base_path: "/sites/1/page_views",
      frame_id: "page_views_stats",
      params: { interval: "daily" }
    ))

    assert_selector "nav[aria-label='Pagination']"
  end

  test "does not render for single page" do
    collection = create_paginated_collection(current_page: 1, total_pages: 1)

    render_inline(PaginationComponent.new(
      collection: collection,
      base_path: "/sites/1/page_views",
      frame_id: "page_views_stats"
    ))

    assert_no_selector "nav"
  end

  test "renders turbo frame attribute" do
    collection = create_paginated_collection(current_page: 2, total_pages: 5)

    render_inline(PaginationComponent.new(
      collection: collection,
      base_path: "/sites/1/page_views",
      frame_id: "page_views_stats"
    ))

    assert_selector "a[data-turbo-frame='page_views_stats']"
  end

  test "renders turbo action replace attribute" do
    collection = create_paginated_collection(current_page: 2, total_pages: 5)

    render_inline(PaginationComponent.new(
      collection: collection,
      base_path: "/sites/1/page_views",
      frame_id: "page_views_stats"
    ))

    assert_selector "a[data-turbo-action='replace']"
  end

  test "disables previous on first page" do
    collection = create_paginated_collection(current_page: 1, total_pages: 5)

    render_inline(PaginationComponent.new(
      collection: collection,
      base_path: "/sites/1/page_views",
      frame_id: "page_views_stats"
    ))

    assert_selector "span.cursor-not-allowed", text: "Previous"
    assert_no_selector "a", text: "Previous"
  end

  test "disables next on last page" do
    collection = create_paginated_collection(current_page: 5, total_pages: 5)

    render_inline(PaginationComponent.new(
      collection: collection,
      base_path: "/sites/1/page_views",
      frame_id: "page_views_stats"
    ))

    assert_selector "span.cursor-not-allowed", text: "Next"
    assert_no_selector "a", text: "Next"
  end

  test "renders page numbers" do
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

  test "highlights current page" do
    collection = create_paginated_collection(current_page: 3, total_pages: 5)

    render_inline(PaginationComponent.new(
      collection: collection,
      base_path: "/sites/1/page_views",
      frame_id: "page_views_stats"
    ))

    assert_selector "span[aria-current='page']", text: "3"
  end

  test "includes params in page links" do
    collection = create_paginated_collection(current_page: 1, total_pages: 5)

    render_inline(PaginationComponent.new(
      collection: collection,
      base_path: "/sites/1/page_views",
      frame_id: "page_views_stats",
      params: { interval: "hourly" }
    ))

    assert_selector "a[href*='interval=hourly']"
  end

  test "displays page info" do
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

  test "renders ellipsis for many pages" do
    collection = create_paginated_collection(current_page: 5, total_pages: 10)

    render_inline(PaginationComponent.new(
      collection: collection,
      base_path: "/sites/1/page_views",
      frame_id: "page_views_stats"
    ))

    assert_text "..."
  end

  test "previous link on middle page" do
    collection = create_paginated_collection(current_page: 3, total_pages: 5)

    render_inline(PaginationComponent.new(
      collection: collection,
      base_path: "/sites/1/page_views",
      frame_id: "page_views_stats"
    ))

    assert_selector "a[href*='page=2']"
  end

  test "next link on middle page" do
    collection = create_paginated_collection(current_page: 3, total_pages: 5)

    render_inline(PaginationComponent.new(
      collection: collection,
      base_path: "/sites/1/page_views",
      frame_id: "page_views_stats"
    ))

    assert_selector "a[href*='page=4']"
  end
end
