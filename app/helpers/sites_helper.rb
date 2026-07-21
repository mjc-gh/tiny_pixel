# frozen_string_literal: true

module SitesHelper
  def site_has_utm_data?(site)
    @site_has_utm_data ||= {}
    @site_has_utm_data[site.id] ||= DailyPageStat.for_site(site.id)
      .where(dimension_type: %w[utm_source utm_medium utm_campaign])
      .exists?
  end
end
