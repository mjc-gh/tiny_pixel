# frozen_string_literal: true

class AdminStatCardComponent < ViewComponent::Base
  def initialize(title:, value:, icon:, href:)
    @title = title
    @value = value
    @icon = icon
    @href = href
  end
end
