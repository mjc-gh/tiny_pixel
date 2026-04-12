# frozen_string_literal: true

module ApplicationHelper
  def format_dimension_value(dimension_type, value)
    return "Unknown" if value.blank?

    case dimension_type
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
    t Visitor.browser_values[value.to_i], scope: "visitors.browsers", default: t("visitor.unknown_value")
  end

  def format_device_type_enum(value)
    t Visitor.device_type_values[value.to_i], scope: "visitors.device_types", default: t("visitor.unknown_value")
  end
end
