defmodule Grapevine.AccountsTest do
  use Grapevine.DataCase
  use Bamboo.Test

  alias Grapevine.Accounts
  alias Grapevine.Accounts.User
  alias Grapevine.Emails

  describe "registering a new account" do
    test "successful" do
      {:ok, user} =
        Accounts.register(%{
          username: "adminuser",
          email: "admin@example.com",
          password: "password",
          password_confirmation: "password"
        })

      assert user.email == "admin@example.com"
      assert user.password_hash
    end
  end

  describe "updating a user" do
    test "successful" do
      user = create_user()

      {:ok, user} = Accounts.update(user, %{
        username: "user",
        email: "user@example.com"
      })

      assert user.username == "adminuser"
      assert user.email == "user@example.com"
    end

    test "editing username" do
      user = create_user()
      user = %{user | username: nil}

      {:ok, user} = Accounts.update(user, %{
        username: "user",
        email: "user@example.com"
      })

      assert user.username == "user"
      assert user.email == "user@example.com"
    end
  end

  describe "changing a password" do
    setup [:with_user]

    test "correct current password", %{user: user} do
      {:ok, user} = Accounts.change_password(user, "password", %{
        password: "p@ssw0rd",
        password_confirmation: "p@ssw0rd"
      })

      assert {:ok, _user} = Accounts.validate_login(user.email, "p@ssw0rd")
    end

    test "invalid current password", %{user: user} do
      {:error, :invalid} = Accounts.change_password(user, "p2ssword", %{
        password: "p@ssw0rd",
        password_confirmation: "p@ssw0rd"
      })
    end

    test "invalid new passwords", %{user: user} do
      {:error, _changeset} = Accounts.change_password(user, "password", %{
        password: "p@ssw0rd",
        password_confirmation: "p@ssw0r"
      })
    end
  end

  describe "checking admin status" do
    test "a user" do
      user = %User{role: "user"}
      refute Accounts.is_admin?(user)
    end

    test "an user" do
      user = %User{role: "admin"}
      assert Accounts.is_admin?(user)
    end
  end

  describe "verifying a password" do
    setup do
      %{user: create_user(%{username: "user", password: "password"})}
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
    %{user: create_user(%{username: "user", email: "user@example.com"})}
  end
end
