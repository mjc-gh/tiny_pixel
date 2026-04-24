# frozen_string_literal: true

require "test_helper"

class AlertComponentTest < ViewComponent::TestCase
  test "renders with success variant" do
    render_inline(AlertComponent.new(variant: :success, message: "Changes saved!"))

    assert_selector "[role='alert']"
    assert_text "Success"
    assert_text "Changes saved!"
  end

  test "renders with danger variant" do
    render_inline(AlertComponent.new(variant: :danger, message: "Error occurred"))

    assert_selector "[role='alert']"
    assert_text "Error"
    assert_text "Error occurred"
  end

  test "renders with warning variant" do
    render_inline(AlertComponent.new(variant: :warning, message: "Warning message"))

    assert_selector "[role='alert']"
    assert_text "Warning"
    assert_text "Warning message"
  end

  test "default variant is danger" do
    render_inline(AlertComponent.new(message: "Some message"))

    assert_text "Error"
  end

  test "applies success css classes" do
    render_inline(AlertComponent.new(variant: :success, message: "test"))

    assert_selector ".bg-success-bg"
    assert_selector ".border-success-border"
    assert_selector ".text-success-text"
  end

  test "applies danger css classes" do
    render_inline(AlertComponent.new(variant: :danger, message: "test"))

    assert_selector ".bg-danger-bg"
    assert_selector ".border-danger-border"
    assert_selector ".text-danger-text"
  end

  test "applies warning css classes" do
    render_inline(AlertComponent.new(variant: :warning, message: "test"))

    assert_selector ".bg-warning-bg"
    assert_selector ".border-warning-border"
    assert_selector ".text-warning-text"
  end

  test "includes stimulus controller" do
    render_inline(AlertComponent.new(message: "test"))

    assert_selector "[data-controller='alert']"
  end

  test "sets dismiss after value" do
    render_inline(AlertComponent.new(message: "test", dismiss_after: 3000))

    assert_selector "[data-alert-dismiss-after-value='3000']"
  end

  test "sets default dismiss after value for danger" do
    render_inline(AlertComponent.new(variant: :danger, message: "test"))

    assert_selector "[data-alert-dismiss-after-value='500000']"
  end

  test "sets custom dismiss after value for success" do
    render_inline(AlertComponent.new(variant: :success, message: "test", dismiss_after: 5000))

    assert_selector "[data-alert-dismiss-after-value='5000']"
  end

  test "includes dismiss button" do
    render_inline(AlertComponent.new(message: "test"))

    assert_selector "button[data-action='alert#close']"
  end

  test "includes heroicon in dismiss button" do
    render_inline(AlertComponent.new(message: "test"))

    assert_selector "button svg"
  end

  test "renders unique id based on variant" do
    render_inline(AlertComponent.new(variant: :success, message: "test"))

    assert_selector "#flash-success"
  end

  test "invalid variant defaults to danger" do
    render_inline(AlertComponent.new(variant: :invalid, message: "test"))

    assert_text "Error"
    assert_selector ".bg-danger-bg"
  end

  test "renders message content" do
    message = "This is a test message"
    render_inline(AlertComponent.new(message: message))

    assert_text message
  end

  test "empty message renders" do
    render_inline(AlertComponent.new(message: ""))

    assert_selector "[role='alert']"
  end
end
