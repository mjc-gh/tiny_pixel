# frozen_string_literal: true

require "test_helper"

class AlertComponentTest < ViewComponent::TestCase
  def test_renders_with_success_variant
    render_inline(AlertComponent.new(variant: :success, message: "Changes saved!"))

    assert_selector "[role='alert']"
    assert_text "Success"
    assert_text "Changes saved!"
  end

  def test_renders_with_danger_variant
    render_inline(AlertComponent.new(variant: :danger, message: "Error occurred"))

    assert_selector "[role='alert']"
    assert_text "Error"
    assert_text "Error occurred"
  end

  def test_renders_with_warning_variant
    render_inline(AlertComponent.new(variant: :warning, message: "Warning message"))

    assert_selector "[role='alert']"
    assert_text "Warning"
    assert_text "Warning message"
  end

  def test_default_variant_is_danger
    render_inline(AlertComponent.new(message: "Some message"))

    assert_text "Error"
  end

  def test_applies_success_css_classes
    render_inline(AlertComponent.new(variant: :success, message: "test"))

    assert_selector ".bg-success-bg"
    assert_selector ".border-success-border"
    assert_selector ".text-success-text"
  end

  def test_applies_danger_css_classes
    render_inline(AlertComponent.new(variant: :danger, message: "test"))

    assert_selector ".bg-danger-bg"
    assert_selector ".border-danger-border"
    assert_selector ".text-danger-text"
  end

  def test_applies_warning_css_classes
    render_inline(AlertComponent.new(variant: :warning, message: "test"))

    assert_selector ".bg-warning-bg"
    assert_selector ".border-warning-border"
    assert_selector ".text-warning-text"
  end

  def test_includes_stimulus_controller
    render_inline(AlertComponent.new(message: "test"))

    assert_selector "[data-controller='alert']"
  end

  def test_sets_dismiss_after_value
    render_inline(AlertComponent.new(message: "test", dismiss_after: 3000))

    assert_selector "[data-alert-dismiss-after-value='3000']"
  end

  def test_sets_default_dismiss_after_value_for_danger
    render_inline(AlertComponent.new(variant: :danger, message: "test"))

    assert_selector "[data-alert-dismiss-after-value='500000']"
  end

  def test_sets_custom_dismiss_after_value_for_success
    render_inline(AlertComponent.new(variant: :success, message: "test", dismiss_after: 5000))

    assert_selector "[data-alert-dismiss-after-value='5000']"
  end

  def test_includes_dismiss_button
    render_inline(AlertComponent.new(message: "test"))

    assert_selector "button[data-action='alert#close']"
  end

  def test_includes_heroicon_in_dismiss_button
    render_inline(AlertComponent.new(message: "test"))

    assert_selector "button svg"
  end

  def test_renders_unique_id_based_on_variant
    render_inline(AlertComponent.new(variant: :success, message: "test"))

    assert_selector "#flash-success"
  end

  def test_invalid_variant_defaults_to_danger
    render_inline(AlertComponent.new(variant: :invalid, message: "test"))

    assert_text "Error"
    assert_selector ".bg-danger-bg"
  end

  def test_renders_message_content
    message = "This is a test message"
    render_inline(AlertComponent.new(message: message))

    assert_text message
  end

  def test_empty_message_renders
    render_inline(AlertComponent.new(message: ""))

    assert_selector "[role='alert']"
  end
end
