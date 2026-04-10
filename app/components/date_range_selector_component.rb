# frozen_string_literal: true

class DateRangeSelectorComponent < ViewComponent::Base
  def initialize(start_date:, end_date:, site:)
    @start_date = start_date
    @end_date = end_date
    @site = site
  end

  def start_date_value
    @start_date&.iso8601
  end

  def end_date_value
    @end_date&.iso8601
  end
end
