defmodule GrapevineData.AccountsTest do
  use Grapevine.DataCase

  alias GrapevineData.Accounts
  alias GrapevineData.Accounts.User

  doctest GrapevineData.Accounts

  describe "registering a new account" do
    test "successful" do
      {:ok, user} =
        Accounts.register(%{
          username: "adminuser",
          email: "admin@example.com",
          password: "password",
          password_confirmation: "password"
        }, fn _user -> :ok end)

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
      }, fn result, _user -> result end)

      assert user.username == "adminuser"
      assert user.email == "user@example.com"
    end

    test "editing username" do
      user = create_user()
      user = %{user | username: nil}

      {:ok, user} = Accounts.update(user, %{
        username: "user",
        email: "user@example.com"
      }, fn result, _user -> result end)

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

  describe "validating an email address" do
    test "user found" do
      user = create_user()

      {:ok, user} = Accounts.verify_email(user.email_verification_token)

      assert user.email_verified_at
    end

    test "reset the token with a valid token" do
      user = create_user()

      {:ok, user} = Accounts.verify_email(user.email_verification_token)

      refute user.email_verification_token
    end

    test "token does not exist" do
      {:error, :invalid} = Accounts.verify_email(UUID.uuid4())
    end

    test "token is not a uuid" do
      {:error, :invalid} = Accounts.verify_email("invalid")
    end
  end

  def with_user(_) do
    %{user: create_user(%{username: "user", email: "user@example.com"})}
  end
end
