defmodule Grapevine.Accounts.UserTest do
  use Grapevine.DataCase

  alias Grapevine.Accounts.User

  describe "validations" do
    setup do
      %{user: %User{}}
    end

    test "trims username and email", %{user: user} do
      changeset = User.changeset(user, %{
        username: "user ",
        email: "user@example.com ",
      })

      assert changeset.changes[:username] == "user"
      assert changeset.changes[:email] == "user@example.com"
    end

    test "blocked list of names", %{user: user} do
      changeset = User.changeset(user, %{
        username: "admin",
      })

      assert Keyword.has_key?(changeset.errors, :username)
    end

    test "matches the blocked name even different case", %{user: user} do
      changeset = User.changeset(user, %{
        username: "AdMiN",
      })

      assert Keyword.has_key?(changeset.errors, :username)
    end
  end
end
