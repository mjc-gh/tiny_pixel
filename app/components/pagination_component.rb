# frozen_string_literal: true

class PaginationComponent < ViewComponent::Base
  def initialize(collection:, base_path:, frame_id:, params: {})
    @collection = collection
    @base_path = base_path
    @frame_id = frame_id
    @params = params
  end

  def render?
    @collection.respond_to?(:total_pages) && @collection.total_pages > 1
  end

  delegate :current_page, to: :@collection

  delegate :total_pages, to: :@collection

  delegate :previous_page, to: :@collection

  delegate :next_page, to: :@collection

  def page_path(page)
    query_params = @params.merge(page: page).to_query
    "#{@base_path}?#{query_params}"
  end

  def turbo_attributes
    {
      "data-turbo-frame" => @frame_id,
      "data-turbo-action" => "replace"
    }
  end

  def page_numbers
    window = 2
    left = [1, current_page - window].max
    right = [total_pages, current_page + window].min

    pages = []
    pages << 1 if left > 1
    pages << nil if left > 2
    (left..right).each { |n| pages << n }
    pages << nil if right < total_pages - 1
    pages << total_pages if right < total_pages
    pages
  end
end
