# frozen_string_literal: true

class DimensionTableComponent < ViewComponent::Base
  def initialize(stats:, dimension_type:, frame_id:, site:, base_path:, params: {})
    @stats = stats
    @dimension_type = dimension_type
    @frame_id = frame_id
    @site = site
    @base_path = base_path
    @params = params
  end

  def dimension_label
    case @dimension_type
    when "country"
      "Countries"
    when "browser"
      "Browsers"
    when "device_type"
      "Device Types"
    when "referrer_hostname"
      "Referrers"
    else
      @dimension_type.humanize
    end
  end

  def dimension_display_name(value)
    return "Unknown" if value.blank?

    case @dimension_type
    when "browser"
      format_browser_enum(value)
    when "device_type"
      format_device_type_enum(value)
    else
      value
    end
  end

  private

  def format_browser_enum(value)
    browser_enums = {
      "1" => "Chrome",
      "2" => "Edge",
      "3" => "Safari",
      "4" => "Firefox",
      "5" => "Opera",
      "999" => "Other"
    }
    browser_enums[value.to_s] || "Unknown"
  end

  def format_device_type_enum(value)
    device_type_enums = {
      "1" => "Desktop",
      "2" => "Mobile",
      "9" => "Crawler",
      "10" => "Other"
    }
    device_type_enums[value.to_s] || "Unknown"
  end
end
