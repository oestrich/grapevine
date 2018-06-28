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

  describe "verifying a client id and secret" do
    setup do
      %{game: create_game()}
    end

    test "when valid", %{game: game} do
      assert {:ok, _game} = Games.validate_socket(game.client_id, game.client_secret)
    end

    test "when bad secret", %{game: game} do
      assert {:error, :invalid} = Games.validate_socket(game.client_id, "bad")
    end

    test "when bad id", %{game: game} do
      assert {:error, :invalid} = Games.validate_socket("bad", game.client_id)
    end
  end
end
