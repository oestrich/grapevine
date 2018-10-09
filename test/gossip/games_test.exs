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

  describe "checking a connection matches a user" do
    setup do
      user = create_user()
      %{user: user, game: create_game(user)}
    end

    test "is owned", %{user: user, game: game} do
      {:ok, connection} = Games.create_connection(game, %{type: "web", url: "http://example.com/play"})

      assert Games.user_owns_connection?(user, connection)
    end

    test "is not owned", %{game: game} do
      {:ok, connection} = Games.create_connection(game, %{type: "web", url: "http://example.com/play"})

      user = create_user(%{email: "other@example.com"})
      refute Games.user_owns_connection?(user, connection)
    end
  end

  describe "create a new connection" do
    setup do
      user = create_user()
      %{user: user, game: create_game(user)}
    end

    test "web", %{game: game} do
      {:ok, connection} = Games.create_connection(game, %{type: "web", url: "http://example.com/play"})

      assert connection.game_id == game.id
      assert connection.type == "web"
      assert connection.url == "http://example.com/play"
    end

    test "telnet", %{game: game} do
      {:ok, connection} = Games.create_connection(game, %{type: "telnet", host: "example.com", port: 4000})

      assert connection.game_id == game.id
      assert connection.type == "telnet"
      assert connection.host == "example.com"
      assert connection.port == 4000
    end

    test "secure telnet", %{game: game} do
      {:ok, connection} = Games.create_connection(game, %{type: "secure telnet", host: "example.com", port: 4000})

      assert connection.game_id == game.id
      assert connection.type == "secure telnet"
      assert connection.host == "example.com"
      assert connection.port == 4000
    end
  end

  describe "update a connection" do
    setup do
      user = create_user()
      %{user: user, game: create_game(user)}
    end

    test "web", %{game: game} do
      {:ok, connection} = Games.create_connection(game, %{type: "web", url: "http://example.com/play"})
      {:ok, connection} = Games.update_connection(connection, %{url: "http://example.com/"})

      assert connection.url == "http://example.com/"
    end

    test "telnet", %{game: game} do
      {:ok, connection} = Games.create_connection(game, %{type: "telnet", host: "example.com", port: 4000})
      {:ok, connection} = Games.update_connection(connection, %{host: "game.example.com"})

      assert connection.host == "game.example.com"
    end

    test "secure telnet", %{game: game} do
      {:ok, connection} = Games.create_connection(game, %{type: "secure telnet", host: "example.com", port: 4000})
      {:ok, connection} = Games.update_connection(connection, %{host: "game.example.com"})

      assert connection.host == "game.example.com"
    end
  end

  describe "delete a connection" do
    setup do
      user = create_user()
      %{user: user, game: create_game(user)}
    end

    test "deletes it", %{game: game} do
      {:ok, connection} = Games.create_connection(game, %{type: "web", url: "http://example.com/play"})

      {:ok, _connection} = Games.delete_connection(connection)
    end
  end
end
