# frozen_string_literal: true

class ViewModeSelectorComponent < ViewComponent::Base
  VIEW_MODES = [
    { value: "graph", label: "Graph" },
    { value: "table", label: "Table" }
  ].freeze

  def initialize(current_view_mode:, site:, current_interval:)
    @current_view_mode = current_view_mode
    @site = site
    @current_interval = current_interval
  end

  def view_modes
    VIEW_MODES
  end

  def selected?(value)
    @current_view_mode == value
  end

  def view_mode_path(view_mode)
    helpers.site_path(@site, interval: @current_interval, view_mode: view_mode)
  end
end
