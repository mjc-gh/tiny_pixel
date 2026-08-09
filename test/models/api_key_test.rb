# frozen_string_literal: true

require "test_helper"

class ApiKeyTest < ActiveSupport::TestCase
  test "generates a high entropy prefixed token and stores only its digest" do
    api_key = ApiKey.create!(user: users(:alice), name: "CLI")

    assert_match %r{\Atiny_pixel_[A-Za-z0-9_-]{43}\z}, api_key.token
    assert_equal Digest::SHA256.hexdigest(api_key.token), api_key.token_digest
    assert_nil api_key.attributes["token"]
  end

  test "does not rotate token across validation retries" do
    api_key = ApiKey.new(user: users(:alice))

    assert_not api_key.valid?
    token = api_key.token
    api_key.name = "Stable"
    assert api_key.valid?
    assert_equal token, api_key.token
  end

  test "requires a name of at most 100 characters" do
    assert_not ApiKey.new(user: users(:alice), name: "").valid?
    assert_not ApiKey.new(user: users(:alice), name: "a" * 101).valid?
    assert ApiKey.new(user: users(:alice), name: "a" * 100).valid?
  end

  test "rejects expiration at or before now" do
    assert_not ApiKey.new(user: users(:alice), name: "Key", expires_at: Time.current).valid?
    assert_not ApiKey.new(user: users(:alice), name: "Key", expires_at: 1.minute.ago).valid?
    assert ApiKey.new(user: users(:alice), name: "Key", expires_at: 1.minute.from_now).valid?
  end

  test "authenticates active, non-expiring, and rejects invalid tokens" do
    key = ApiKey.create!(user: users(:alice), name: "Auth")

    assert_equal key, ApiKey.authenticate(key.token)
    assert_equal api_keys(:alice_never), ApiKey.authenticate("fixture-alice-never")
    assert_nil ApiKey.authenticate(nil)
    assert_nil ApiKey.authenticate("")
    assert_nil ApiKey.authenticate("unknown")
    assert_nil ApiKey.authenticate("fixture-alice-expired")
  end

  test "expired keys include the expiration boundary" do
    key = api_keys(:alice_future)
    key.update_column(:expires_at, Time.current)

    assert key.expired?
    assert_not ApiKey.active.exists?(key.id)
  end

  test "duplicate generated tokens are rejected by the unique index" do
    SecureRandom.stub :urlsafe_base64, "same-token" do
      ApiKey.create!(user: users(:alice), name: "First")

      assert_raises ActiveRecord::RecordNotUnique do
        ApiKey.create!(user: users(:alice), name: "Second")
      end
    end
  end

  test "user deletion removes API keys" do
    user = User.create!(email: "api-key-owner@example.com", password: "password12345", password_confirmation: "password12345")
    user.api_keys.create!(name: "Owned")

    assert_difference "ApiKey.count", -1 do
      user.destroy!
    end
  end
end
