# frozen_string_literal: true

class IntervalSelectorComponent < ViewComponent::Base
  INTERVALS = [
    { value: "hourly", label: "Hourly" },
    { value: "daily", label: "Daily" },
    { value: "weekly", label: "Weekly" }
  ].freeze

  def initialize(current_interval:, site:)
    @current_interval = current_interval
    @site = site
  end

  def intervals
    INTERVALS
  end

  def selected?(value)
    @current_interval == value
  end

  def interval_path(interval)
    helpers.site_path(@site, interval: interval)
  end
end
