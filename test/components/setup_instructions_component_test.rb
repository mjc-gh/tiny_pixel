# frozen_string_literal: true

require "test_helper"

class SetupInstructionsComponentTest < ViewComponent::TestCase
  def test_renders_slideover_controller
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_selector "[data-controller='slideover']"
  end

  def test_slideover_has_turbo_temporary_attribute
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_selector "[data-controller='slideover'][data-turbo-temporary]"
  end

  def test_renders_dialog_element
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_selector "dialog[data-slideover-target='dialog']"
  end

  def test_renders_title
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_text I18n.t("sites.instructions.title")
  end

  def test_renders_description
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_text I18n.t("sites.instructions.description")
  end

  def test_renders_tracking_snippet_with_property_id
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_includes rendered_content, "data-property-id=&quot;#{site.property_id}&quot;"
  end

  def test_renders_tracking_snippet_with_server_attribute
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_includes rendered_content, "data-server=&quot;http://localhost:3000&quot;"
  end

  def test_renders_tracking_script_source
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_includes rendered_content, "src=&quot;http://localhost:3000/tp.js&quot;"
  end

  def test_renders_copy_button
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_text I18n.t("sites.instructions.copy")
  end

  def test_copy_button_has_clipboard_controller
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_selector "div[data-controller='clipboard']"
  end

  def test_renders_close_button
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_text I18n.t("sites.instructions.close")
  end

  def test_close_button_has_slideover_action
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_selector "button[data-action='slideover#close']", count: 2
  end

  def test_renders_close_icon
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_selector "svg"
  end

  def test_snippet_contains_script_tag
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "http://localhost:3000")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_includes rendered_content, "&lt;script"
  end

  def test_different_base_urls_generate_correct_snippets
    site = sites(:tech_blog)
    request = OpenStruct.new(base_url: "https://example.com")

    render_inline(SetupInstructionsComponent.new(site: site, request: request))

    assert_includes rendered_content, "src=&quot;https://example.com/tp.js&quot;"
    assert_includes rendered_content, "data-server=&quot;https://example.com&quot;"
  end
end
