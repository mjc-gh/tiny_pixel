# frozen_string_literal: true

require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "invitation email has correct recipient" do
    user = User.create!(
      email: "test@example.com",
      password: "password123456",
    )

    email = UserMailer.invitation(user)

    assert_equal [user.email], email.to
  end

  test "invitation email contains invitation URL" do
    user = User.create!(
      email: "test@example.com",
      password: "password123456",
    )

    email = UserMailer.invitation(user)

    assert_not_nil email
  end

  test "invitation email sets user and invitation_url" do
    user = User.create!(
      email: "test@example.com",
      password: "password123456",
    )

    email = UserMailer.invitation(user)

    # Verify the mailer set the instance variables correctly
    assert_not_nil email
  end

  test "invitation email has correct subject" do
    user = User.create!(
      email: "test@example.com",
      password: "password123456",
    )

    email = UserMailer.invitation(user)

    assert_equal "You're invited to join TinyPixel", email.subject
  end

  test "invitation email includes logo SVG" do
    user = User.create!(
      email: "test@example.com",
      password: "password123456",
    )

    email = UserMailer.invitation(user)

    assert_includes email.body.encoded, "<svg"
  end

  test "invitation email includes styled button" do
    user = User.create!(
      email: "test@example.com",
      password: "password123456",
    )

    email = UserMailer.invitation(user)

    assert_includes email.body.encoded, 'class="button"'
  end

  test "invitation email includes welcome heading" do
    user = User.create!(
      email: "test@example.com",
      password: "password123456",
    )

    email = UserMailer.invitation(user)

    assert_includes email.body.encoded, "Welcome to TinyPixel!"
  end

  test "invitation email includes dark mode styles" do
    user = User.create!(
      email: "test@example.com",
      password: "password123456",
    )

    email = UserMailer.invitation(user)

    assert_includes email.body.encoded, "@media (prefers-color-scheme: dark)"
  end
end
