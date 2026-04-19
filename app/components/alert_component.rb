# frozen_string_literal: true

class AlertComponent < ViewComponent::Base
  VALID_VARIANTS = [:success, :danger, :warning].freeze
  DEFAULT_VARIANT = :danger
  DEFAULT_DISMISS_AFTER = 500000

  def initialize(variant: DEFAULT_VARIANT, message: "", dismiss_after: DEFAULT_DISMISS_AFTER)
    @variant = validate_variant(variant)
    @message = message
    @dismiss_after = dismiss_after
  end

  def variant_title
    case @variant
    when :success
      "Success"
    when :danger
      "Error"
    when :warning
      "Warning"
    end
  end

  private

  def validate_variant(variant)
    return variant if VALID_VARIANTS.include?(variant)

    DEFAULT_VARIANT
  end
end
