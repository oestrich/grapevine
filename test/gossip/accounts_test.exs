defmodule Gossip.AccountsTest do
  use Gossip.DataCase
  use Bamboo.Test

  alias Gossip.Accounts
  alias Gossip.Accounts.User
  alias Gossip.Emails

  describe "registering a new account" do
    test "successful" do
      {:ok, game} =
        Accounts.register(%{
          email: "admin@example.com",
          password: "password",
          password_confirmation: "password"
        })

      assert game.email == "admin@example.com"
      assert game.password_hash
    end
  end

  describe "verifying a password" do
    setup do
      %{user: create_user(%{password: "password"})}
    end

    test "when valid", %{user: user} do
      assert {:ok, _user} = Accounts.validate_login(user.email, "password")
    end

    test "when invalid", %{user: user} do
      assert {:error, :invalid} = Accounts.validate_login(user.email, "passw0rd")
    end

    test "when bad email" do
      assert {:error, :invalid} = Accounts.validate_login("unknown@email.com", "passw0rd")
    end
  end

  describe "resetting password" do
    setup [:with_user]

    test "email does not exist" do
      :ok = Accounts.start_password_reset("not-found@example.com")

      assert_no_emails_delivered()
    end

    test "user found", %{user: user} do
      :ok = Accounts.start_password_reset(user.email)

      user = Repo.get(User, user.id)
      assert user.password_reset_token

      assert_delivered_email(Emails.password_reset(user))
    end

    test "reset the token with a valid token", %{user: user} do
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

    test "token is expired", %{user: user} do
      :ok = Accounts.start_password_reset(user.email)
      user = Repo.get(User, user.id)

      user
      |> Ecto.Changeset.change(%{password_reset_expires_at: Timex.now() |> Timex.shift(hours: -1)})
      |> Repo.update()

      params = %{password: "new password", password_confirmation: "new password"}
      assert :error = Accounts.reset_password(user.password_reset_token, params)
    end
  end

  def with_user(_) do
    %{user: create_user(%{email: "user@example.com"})}
  end
end
