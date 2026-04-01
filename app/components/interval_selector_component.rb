# frozen_string_literal: true

class IntervalSelectorComponent < ViewComponent::Base
  INTERVALS = [
    { value: "hourly", label: "Hourly" },
    { value: "daily", label: "Daily" },
    { value: "weekly", label: "Weekly" }
  ].freeze

  def initialize(current_interval:, site:, current_view_mode: "graph")
    @current_interval = current_interval
    @site = site
    @current_view_mode = current_view_mode
  end

  def intervals
    INTERVALS
  end

  def selected?(value)
    @current_interval == value
  end

  def interval_path(interval)
    helpers.site_path(@site, interval: interval, view_mode: @current_view_mode)
  end
end
