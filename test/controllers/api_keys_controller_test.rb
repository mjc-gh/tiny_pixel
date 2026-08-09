# frozen_string_literal: true

require "test_helper"

class ApiKeysControllerTest < ActionDispatch::IntegrationTest
  test "all actions require authentication" do
    get api_keys_url
    assert_redirected_to login_path

    get new_api_key_url
    assert_redirected_to login_path

    post api_keys_url, params: { api_key: { name: "Key" } }
    assert_redirected_to login_path

    delete api_key_url(api_keys(:alice_never))
    assert_redirected_to login_path
  end

  test "index lists only current user's keys newest first" do
    login(users(:alice))

    get api_keys_url

    assert_response :success
    assert_select "h2", text: "Future key"
    assert_select "h2", text: "Bob key", count: 0
  end

  test "index shows empty state" do
    user = User.create!(email: "empty-api@example.com", password: "password12345", password_confirmation: "password12345")
    login(user, password: "password12345")

    get api_keys_url

    assert_select "p", text: I18n.t("api_keys.index.empty")
  end

  test "new shows key form" do
    login(users(:alice))

    get new_api_key_url

    assert_select "input#api_key_name[required]"
    assert_select "input#api_key_expires_at[type='datetime-local']"
  end

  test "create reveals the token once and does not persist it" do
    login(users(:alice))

    post api_keys_url, params: { api_key: { name: "Deploy" } }

    key = users(:alice).api_keys.order(:created_at).last
    assert_redirected_to api_keys_path
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_match(/tiny_pixel_/, flash[:api_key_token])
    assert_nil key.attributes["token"]
    get api_keys_url
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_select "[data-turbo-temporary] code", count: 1
    get api_keys_url
    assert_select "[data-turbo-temporary]", count: 0
  end

  test "invalid create renders unprocessable form" do
    login(users(:alice))

    post api_keys_url, params: { api_key: { name: "" } }

    assert_response :unprocessable_entity
    assert_select ".bg-danger-bg"
  end

  test "ignores ownership and digest parameters" do
    login(users(:alice))

    post api_keys_url, params: { api_key: { name: "Scoped", user_id: users(:bob).id, token_digest: "bad" } }

    key = users(:alice).api_keys.order(:created_at).last
    assert_equal users(:alice), key.user
    assert_not_equal "bad", key.token_digest
  end

  test "revokes current user's key and isolates other users" do
    login(users(:alice))

    delete api_key_url(api_keys(:alice_never))
    assert_response :see_other
    assert_not ApiKey.exists?(api_keys(:alice_never).id)

    delete api_key_url(api_keys(:bob_key))
    assert_response :not_found
  end
end
