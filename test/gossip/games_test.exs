defmodule Gossip.GamesTest do
  use Gossip.DataCase

  alias Gossip.Games

  describe "registering a new game" do
    test "successful" do
      {:ok, game} = Games.register(%{
        name: "A MUD",
        email: "admin@example.com",
        password: "password",
        password_confirmation: "password",
      })

      assert game.name == "A MUD"
      assert game.email == "admin@example.com"
      assert game.password_hash
      assert game.client_id
      assert game.client_secret
    end
  end

  describe "verifying a password" do
    setup do
      %{game: create_game(%{password: "password"})}
    end

    test "when valid", %{game: game} do
      assert {:ok, _game} = Games.validate_login(game.email, "password")
    end

    test "when invalid", %{game: game} do
      assert {:error, :invalid} = Games.validate_login(game.email, "passw0rd")
    end

    test "when bad email" do
      assert {:error, :invalid} = Games.validate_login("unknown@email.com", "passw0rd")
    end
  end
end
