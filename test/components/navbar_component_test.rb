# frozen_string_literal: true

require "test_helper"

class NavbarComponentTest < ViewComponent::TestCase
  def test_renders_navigation_container
    render_inline(NavbarComponent.new(current_user: nil))

    assert_selector "nav"
  end

  def test_renders_home_link
    render_inline(NavbarComponent.new(current_user: nil))

    assert_link "tiny_pixel", href: "/"
  end

  def test_signed_in_user_sees_sites_link
    user = users(:alice)

    render_inline(NavbarComponent.new(current_user: user))

    assert_link "Sites", href: "/sites"
  end

  def test_signed_in_user_sees_profile_link
    user = users(:alice)

    render_inline(NavbarComponent.new(current_user: user))

    assert_link "Profile", href: "/profile"
  end

  def test_signed_in_user_sees_logout_link
    user = users(:alice)

    render_inline(NavbarComponent.new(current_user: user))

    assert_selector "a[href='/logout'][data-turbo-method='delete']", text: "Logout"
  end

  def test_signed_in_user_does_not_see_login_or_sign_up
    user = users(:alice)

    render_inline(NavbarComponent.new(current_user: user))

    assert_no_link "Login"
    assert_no_link "Sign Up"
  end

  def test_signed_out_user_sees_login_link
    render_inline(NavbarComponent.new(current_user: nil))

    assert_link "Login", href: "/login"
  end

  def test_signed_out_user_sees_sign_up_link
    render_inline(NavbarComponent.new(current_user: nil))

    assert_link "Sign Up", href: "/sign_up"
  end

  def test_signed_out_user_does_not_see_sites_profile_or_logout
    render_inline(NavbarComponent.new(current_user: nil))

    assert_no_link "Sites"
    assert_no_link "Profile"
    assert_no_link "Logout"
  end
end
