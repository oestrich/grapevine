defmodule Grapevine.AccountsTest do
  use Grapevine.DataCase
  use Bamboo.Test

  alias Grapevine.Accounts
  alias Grapevine.Emails
  alias GrapevineData.Accounts.User

  describe "registration" do
    test "sends an email to verify the email" do
      {:ok, user} =
        Accounts.register(%{
          username: "adminuser",
          email: "admin@example.com",
          password: "password",
          password_confirmation: "password"
        })

      assert_delivered_email(Emails.verify_email(user))
    end
  end

  describe "updating a user" do
    test "does not send an email if the email did not update" do
      user = create_user()
      {:ok, user} = Accounts.verify_email(user.email_verification_token)

      {:ok, user} = Accounts.update(user, %{email: user.email})

      refute_delivered_email(Emails.verify_email(user))
    end

    test "sends an email to verify the email when changing the email" do
      user = create_user()
      {:ok, user} = Accounts.verify_email(user.email_verification_token)

      {:ok, user} = Accounts.update(user, %{email: "new@example.com"})

      refute user.email_verified_at
      assert_delivered_email(Emails.verify_email(user))
    end
  end

  describe "resetting password" do
    test "email does not exist" do
      :ok = Accounts.start_password_reset("not-found@example.com")

      assert_no_emails_delivered()
    end

    test "user found" do
      user = create_user(%{username: "user", email: "user@example.com"})

      :ok = Accounts.start_password_reset(user.email)

      user = Repo.get(User, user.id)
      assert user.password_reset_token

      assert_delivered_email(Emails.password_reset(user))
    end

    test "reset the token with a valid token" do
      user = create_user(%{username: "user", email: "user@example.com"})

      :ok = Accounts.start_password_reset(user.email)
      user = Repo.get(User, user.id)

      params = %{password: "new password", password_confirmation: "new password"}
      {:ok, user} = Accounts.reset_password(user.password_reset_token, params)

      refute user.password_reset_token
      refute user.password_reset_expires_at
    end

    test "no token found" do
      params = %{password: "new password", password_confirmation: "new password"}
      assert :error = Accounts.reset_password(UUID.uuid4(), params)
    end

    test "token is not a UUID" do
      params = %{password: "new password", password_confirmation: "new password"}
      assert :error = Accounts.reset_password("a token", params)
    end

    test "token is expired" do
      user = create_user(%{username: "user", email: "user@example.com"})

      :ok = Accounts.start_password_reset(user.email)
      user = Repo.get(User, user.id)

      user
      |> Ecto.Changeset.change(%{password_reset_expires_at: Timex.now() |> Timex.shift(hours: -1)})
      |> Repo.update()

      params = %{password: "new password", password_confirmation: "new password"}
      assert :error = Accounts.reset_password(user.password_reset_token, params)
    end
  end
end
