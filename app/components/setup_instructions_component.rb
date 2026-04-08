# frozen_string_literal: true

class SetupInstructionsComponent < ViewComponent::Base
  def initialize(site:, request:)
    @site = site
    @request = request
  end

  delegate :base_url, to: :@request

  def tracking_snippet
    <<~HTML
      <script src="#{base_url}/tp.js" data-property-id="#{@site.property_id}" data-server="#{base_url}"></script>
    HTML
  end
end
