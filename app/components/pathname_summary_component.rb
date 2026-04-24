# frozen_string_literal: true

class PathnameSummaryComponent < ViewComponent::Base
  def initialize(stats:, frame_id: nil, base_path: nil, params: {}, display_hostname: false)
    @stats_relation = stats
    @frame_id = frame_id
    @base_path = base_path
    @params = params
    @display_hostname = display_hostname
  end

  def render_pagination?
    @stats_relation&.respond_to?(:total_pages) && @frame_id.present? && @base_path.present?
  end

  def stats
    @stats ||= @stats_relation.map { |row| build_stat_from_row(row) }
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

  private

  def build_stat_from_row(row)
    PageviewStat.new(
      hostname: @display_hostname ? row.hostname : nil,
      pathname: row.pathname,
      pageviews: row.pageviews.to_i,
      unique_pageviews: row.unique_pageviews.to_i,
      visits: row.visits.to_i,
      sessions: row.sessions.to_i,
      bounced_count: row.bounced_count.to_i,
      total_duration: row.total_duration.to_f,
      duration_count: row.duration_count.to_i
    )
  end
end
