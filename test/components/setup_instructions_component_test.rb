# frozen_string_literal: true

require "test_helper"

class SetupInstructionsComponentTest < ViewComponent::TestCase
  test "renders slideover controller" do
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_selector "[data-controller='slideover']"
  end

  test "slideover has turbo temporary attribute" do
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_selector "[data-controller='slideover'][data-turbo-temporary]"
  end

  test "renders dialog element" do
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_selector "dialog[data-slideover-target='dialog']"
  end

  test "renders title" do
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_text I18n.t("sites.instructions.title")
  end

  test "renders description" do
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_text I18n.t("sites.instructions.description")
  end

  test "renders tracking snippet with property id" do
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_includes rendered_content, "data-property-id=&quot;#{site.property_id}&quot;"
  end

  test "renders tracking snippet with server attribute" do
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_includes rendered_content, "data-server=&quot;http://localhost:3000&quot;"
  end

  test "renders tracking script source" do
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_includes rendered_content, "src=&quot;http://localhost:3000/tp.js&quot;"
  end

  test "renders copy button" do
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_text I18n.t("sites.instructions.copy")
  end

  test "copy button has clipboard controller" do
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_selector "div[data-controller='clipboard']"
  end

  test "renders close button" do
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_text I18n.t("sites.instructions.close")
  end

  test "close button has slideover action" do
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_selector "button[data-action='slideover#close']", count: 2
  end

  test "renders close icon" do
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_selector "svg"
  end

  test "snippet contains script tag" do
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_includes rendered_content, "&lt;script"
  end

  test "different base urls generate correct snippets" do
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "https://example.com")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_includes rendered_content, "src=&quot;https://example.com/tp.js&quot;"
    assert_includes rendered_content, "data-server=&quot;https://example.com&quot;"
  end
end
