# frozen_string_literal: true

class SiteCardComponent < ViewComponent::Base
  def initialize(site:, stats: nil)
    @site = site
    @stats = stats
  end

  private

  def format_duration(seconds)
    return "N/A" if seconds.nil?

    "#{seconds.round}s"
  end

  def granularity_label
    case @stats&.[](:granularity)
    when :hourly
      "Last 24 hours"
    when :daily
      "Last 7 days"
    when :weekly
      "Last 28 days"
    else
      ""
    end
  end
end
