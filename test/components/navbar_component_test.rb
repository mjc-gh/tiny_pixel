# frozen_string_literal: true

require "test_helper"

class NavbarComponentTest < ViewComponent::TestCase
  test "renders navigation container" do
    render_inline(NavbarComponent.new(user: nil))

    assert_selector "nav"
  end

  test "renders home link" do
    render_inline(NavbarComponent.new(user: nil))

    assert_link "tiny_pixel", href: "/"
  end

  test "signed in user sees sites link" do
    user = users(:alice)

    render_inline(NavbarComponent.new(user: user))

    assert_link "Sites", href: "/sites"
  end

  test "signed in user sees profile link" do
    user = users(:alice)

    render_inline(NavbarComponent.new(user: user))

    assert_link "Profile", href: "/profile"
  end

  test "signed in user sees logout link" do
    user = users(:alice)

    render_inline(NavbarComponent.new(user: user))

    assert_selector "a[href='/logout'][data-turbo-method='delete']", text: "Logout"
  end

  test "signed in user does not see login or sign up" do
    user = users(:alice)

    render_inline(NavbarComponent.new(user: user))

    assert_no_link "Login"
    assert_no_link "Sign Up"
  end

  test "signed out user sees login link" do
    render_inline(NavbarComponent.new(user: nil))

    assert_link "Login", href: "/login"
  end

  test "signed out user sees sign up link" do
    render_inline(NavbarComponent.new(user: nil))

    assert_link "Sign Up", href: "/sign_up"
  end

  test "signed out user does not see sites profile or logout" do
    render_inline(NavbarComponent.new(user: nil))

    assert_no_link "Sites"
    assert_no_link "Profile"
    assert_no_link "Logout"
  end
end
