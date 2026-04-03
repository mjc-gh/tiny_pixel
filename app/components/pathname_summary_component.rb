# frozen_string_literal: true

class PathnameSummaryComponent < ViewComponent::Base
  def initialize(stats:, pagination: nil, frame_id: nil, base_path: nil, params: {})
    @stats = stats
    @pagination = pagination
    @frame_id = frame_id
    @base_path = base_path
    @params = params
  end

  def render_pagination?
    @pagination&.respond_to?(:total_pages) && @frame_id.present? && @base_path.present?
  end

  def format_value(stat, method)
    value = stat.public_send(method)
    return "N/A" if value.nil?

    case method
    when :bounce_rate
      "#{value}%"
    when :avg_duration
      "#{value.round(2)}s"
    else
      value.is_a?(Numeric) ? number_with_delimiter(value) : value
    end
  end
end
