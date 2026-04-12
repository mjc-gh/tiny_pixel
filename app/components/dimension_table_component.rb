# frozen_string_literal: true

class DimensionTableComponent < ViewComponent::Base
  def initialize(stats:, type:, frame_id:, site:, base_path:, params: {}, selected_dimension_value: nil)
    @stats = stats
    @type = type
    @frame_id = frame_id
    @site = site
    @base_path = base_path
    @params = params
    @selected_dimension_value = selected_dimension_value
  end

  def dimension_label
    case @type
    when "country"
      "Countries"
    when "browser"
      "Browsers"
    when "device_type"
      "Device Types"
    when "referrer_hostname"
      "Referrers"
    else
      @type.humanize
    end
  end

  def dimension_display_name(value)
    helpers.format_dimension_value(@type, value)
  end

  def is_selected?(value)
    @selected_dimension_value == value
  end
end
