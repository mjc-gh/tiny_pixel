# frozen_string_literal: true

require "test_helper"

class SiteCardComponentTest < ViewComponent::TestCase
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::TranslationHelper
  def test_renders_site_name
    site = sites(:my_blog)

    render_inline(SiteCardComponent.new(site: site))

    assert_selector "h2", text: site.name
  end

  def test_renders_site_property_id
    site = sites(:my_blog)

    render_inline(SiteCardComponent.new(site: site))

    assert_text site.property_id
  end

  def test_renders_formatted_creation_date
    site = sites(:my_blog)

    render_inline(SiteCardComponent.new(site: site))

    assert_text "Created"
  end

  def test_renders_settings_link
    site = sites(:my_blog)

    render_inline(SiteCardComponent.new(site: site))

    assert_selector "a[href='#{edit_site_path(site)}'][title='#{t("common.settings")}']"
  end
end
