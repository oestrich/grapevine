defmodule Gossip.GamesTest do
  use Gossip.DataCase

  alias Gossip.Games

  describe "registering a new game" do
    test "successful" do
      user = create_user()

      {:ok, game} = Games.register(user, %{
        name: "A MUD",
        short_name: "AM",
      })

      assert game.name == "A MUD"
      assert game.client_id
      assert game.client_secret
    end
  end

  describe "verifying a client id and secret" do
    setup do
      %{game: create_game(create_user())}
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

    test "saves the user agent if available", %{game: game} do
      assert {:ok, game} = Games.validate_socket(game.client_id, game.client_secret, %{"user_agent" => "ExVenture 0.23.0"})
      assert game.user_agent == "ExVenture 0.23.0"
    end

    test "registers the user agent locally", %{game: game} do
      assert {:ok, game} = Games.validate_socket(game.client_id, game.client_secret, %{"user_agent" => "ExVenture 0.23.0"})
      assert {:ok, _user_agent} = Games.get_user_agent(game.user_agent)
    end

    test "saves the version if available", %{game: game} do
      assert {:ok, game} = Games.validate_socket(game.client_id, game.client_secret, %{"version" => "1.1.0"})
      assert game.version == "1.1.0"
    end

    test "defaults version if unavailable", %{game: game} do
      assert {:ok, game} = Games.validate_socket(game.client_id, game.client_secret)
      assert game.version == "1.0.0"
    end
  end

  describe "regenerate client id and secret" do
    setup do
      user = create_user()
      %{user: user, game: create_game(user)}
    end

    test "changes the keys", %{user: user, game: game} do
      {:ok, updated_game} = Games.regenerate_client_tokens(user, game.id)

      assert updated_game.client_id != game.client_id
      assert updated_game.client_secret != game.client_secret
    end
  end

  describe "register a user agent" do
    test "successful" do
      {:ok, user_agent} = Games.register_user_agent("ExVenture 0.26.0")

      assert user_agent.version == "ExVenture 0.26.0"
    end

    test "reuses the same agent" do
      {:ok, first_user_agent} = Games.register_user_agent("ExVenture 0.26.0")
      {:ok, second_user_agent} = Games.register_user_agent("ExVenture 0.26.0")

      assert first_user_agent.id == second_user_agent.id
    end
  end
end
