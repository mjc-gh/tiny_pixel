# frozen_string_literal: true

module PaginationHelpers
  def create_paginated_collection(items = [], current_page: 1, total_pages: 1)
    collection = items.dup
    collection.define_singleton_method(:current_page) { current_page }
    collection.define_singleton_method(:total_pages) { total_pages }
    collection.define_singleton_method(:previous_page) { current_page > 1 ? current_page - 1 : nil }
    collection.define_singleton_method(:next_page) { current_page < total_pages ? current_page + 1 : nil }
    collection
  end
end
