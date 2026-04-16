# frozen_string_literal: true

module ApplicationHelper
  include FormBuildable

  define_form_builder :default do
    html_classes do
      form { "space-y-4" }
      field { "flex flex-col" }
      label { "block text-sm font-medium text-content-label mb-1" }
      input { "w-full px-3 py-2 border border-input-border rounded-md bg-input-bg text-content-primary focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent" }
      check_box_input { "rounded border-input-border bg-input-bg text-primary focus:ring-primary focus:ring-2" }
      check_box { "flex items-center gap-3 cursor-pointer" }
      check_box_label { "text-sm font-medium text-content-label" }
      button { "bg-primary text-white py-2 px-4 rounded-md hover:bg-primary-hover focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 font-medium" }
      error_container { "bg-danger-bg border border-danger-border rounded-md p-4" }
      error { "text-sm text-danger-text" }
    end
  end

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
