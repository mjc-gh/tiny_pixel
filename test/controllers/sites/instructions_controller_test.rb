# frozen_string_literal: true

require "test_helper"

module Sites
  class InstructionsControllerTest < ActionDispatch::IntegrationTest
    test "redirects unauthenticated users to login" do
      get site_instructions_url(sites(:tech_blog))

      assert_redirected_to login_path
    end

    test "authenticated users can access show" do
      login(users(:alice))

      get site_instructions_url(sites(:tech_blog))

      assert_response :success
    end

    test "returns turbo frame with instructions" do
      login(users(:alice))

      get site_instructions_url(sites(:tech_blog))

      assert_select "turbo-frame#modals"
    end

    test "renders setup instructions component" do
      login(users(:alice))

      get site_instructions_url(sites(:tech_blog))

      assert_response :success
      assert_select "[data-controller='slideover']"
    end

    test "includes tracking snippet with property_id" do
      login(users(:alice))
      site = sites(:tech_blog)

      get site_instructions_url(site)

      assert_response :success
      assert_includes response.body, "data-property-id=&quot;#{site.property_id}&quot;"
    end

    test "includes tracking snippet with server parameter" do
      login(users(:alice))

      get site_instructions_url(sites(:tech_blog))

      assert_response :success
      assert_includes response.body, "data-server="
    end

    test "returns 404 for unauthorized site" do
      login(users(:bob))

      get site_instructions_url(sites(:tech_blog))

      assert_response :not_found
    end

    test "allows bob to access instructions for my_blog where he is a member" do
      login(users(:bob))

      get site_instructions_url(sites(:my_blog))

      assert_response :success
    end

    test "includes copy button in response" do
      login(users(:alice))

      get site_instructions_url(sites(:tech_blog))

      assert_response :success
      assert_includes response.body, I18n.t("sites.instructions.copy")
    end

    test "includes close button in response" do
      login(users(:alice))

      get site_instructions_url(sites(:tech_blog))

      assert_response :success
      assert_includes response.body, I18n.t("sites.instructions.close")
    end
  end
end
