# frozen_string_literal: true

require "test_helper"

class EnvironTest < ActiveSupport::TestCase
  test "returns the value when the env var is present" do
    assert_equal ENV["USER"], Environ["USER"]
  end

  test "raises MissingEnvVar when the env var is not present" do
    assert_raises(Environ::MissingEnvVar) do
      Environ["NONEXISTENT_ENV_VAR_FOR_TEST"]
    end
  end
end
