# frozen_string_literal: true

require "test_helper"

class SiteCardComponentTest < ViewComponent::TestCase
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::TranslationHelper

  test "renders site name" do
    site = sites(:my_blog)

    render_inline(SiteCardComponent.new(site: site))

    assert_selector "h2", text: site.name
  end

  test "renders site property id" do
    site = sites(:my_blog)

    render_inline(SiteCardComponent.new(site: site))

    assert_text site.property_id
  end

  test "renders formatted creation date" do
    site = sites(:my_blog)

    render_inline(SiteCardComponent.new(site: site))

    assert_text "Created"
  end

  test "renders settings link" do
    site = sites(:my_blog)

    render_inline(SiteCardComponent.new(site: site))

    assert_selector "a[href='#{edit_site_path(site)}'][title='#{t("common.settings")}']"
  end
end
