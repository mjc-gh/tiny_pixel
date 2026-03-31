# frozen_string_literal: true

class SiteCardComponent < ViewComponent::Base
  def initialize(site:)
    @site = site
  end
end
