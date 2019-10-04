defmodule GrapevineData.GamesTest do
  use Grapevine.DataCase

  alias GrapevineData.Games
  alias GrapevineData.UserAgents

  describe "registering a new game" do
    test "successful" do
      user = create_user()

      {:ok, game} =
        Games.register(user, %{
          name: "A MUD",
          short_name: "AM",
          description: "A MUD"
        })

      assert game.name == "A MUD"
      assert game.client_id
      assert game.client_secret
    end
  end

  describe "uploading a new cover image" do
    test "saves the key" do
      game = create_game(create_user())

      {:ok, game} = Games.update(game, %{cover: %{path: "test/fixtures/cover.png"}})

      assert game.cover_key
      assert game.cover_extension
    end
  end

  describe "uploading a new hero image" do
    test "saves the key" do
      game = create_game(create_user())

      {:ok, game} = Games.update(game, %{hero: %{path: "test/fixtures/cover.png"}})

      assert game.hero_key
      assert game.hero_extension
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
      assert {:ok, game} =
               Games.validate_socket(game.client_id, game.client_secret, %{
                 "user_agent" => "ExVenture 0.23.0"
               })

      assert game.user_agent == "ExVenture 0.23.0"
    end

    test "registers the user agent locally", %{game: game} do
      assert {:ok, game} =
               Games.validate_socket(game.client_id, game.client_secret, %{
                 "user_agent" => "ExVenture 0.23.0"
               })

      assert {:ok, _user_agent} = UserAgents.get_user_agent(game.user_agent)
    end

    test "saves the version if available", %{game: game} do
      assert {:ok, game} =
               Games.validate_socket(game.client_id, game.client_secret, %{"version" => "1.1.0"})

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

  describe "checking a connection matches a user" do
    setup do
      user = create_user()
      %{user: user, game: create_game(user)}
    end

    test "is owned", %{user: user, game: game} do
      {:ok, connection} =
        Games.create_connection(game, %{type: "web", url: "http://example.com/play"}, &connection_hook/1)

      assert Games.user_owns_connection?(user, connection)
    end

    test "is not owned", %{game: game} do
      {:ok, connection} =
        Games.create_connection(game, %{type: "web", url: "http://example.com/play"}, &connection_hook/1)

      user = create_user(%{username: "other", email: "other@example.com"})
      refute Games.user_owns_connection?(user, connection)
    end
  end

  describe "create a new connection" do
    setup do
      user = create_user()
      %{user: user, game: create_game(user)}
    end

    test "web", %{game: game} do
      {:ok, connection} =
        Games.create_connection(game, %{type: "web", url: "http://example.com/play"}, &connection_hook/1)

      assert connection.game_id == game.id
      assert connection.type == "web"
      assert connection.url == "http://example.com/play"
    end

    test "telnet", %{game: game} do
      {:ok, connection} =
        Games.create_connection(game, %{type: "telnet", host: "example.com", port: 4000}, &connection_hook/1)

      assert connection.game_id == game.id
      assert connection.type == "telnet"
      assert connection.host == "example.com"
      assert connection.port == 4000
    end

    test "secure telnet", %{game: game} do
      {:ok, connection} =
        Games.create_connection(game, %{type: "secure telnet", host: "example.com", port: 4000}, &connection_hook/1)

      assert connection.game_id == game.id
      assert connection.type == "secure telnet"
      assert connection.host == "example.com"
      assert connection.port == 4000
    end

    test "limited to a single connection per type", %{game: game} do
      {:ok, _connection} = Games.create_connection(game, %{
        type: "secure telnet",
        host: "example.com",
        port: 4000
      }, &connection_hook/1)

      {:error, changeset} = Games.create_connection(game, %{
        type: "secure telnet",
        host: "example.com",
        port: 4000
      }, &connection_hook/1)

      assert changeset.errors[:type]
    end
  end

  describe "update a connection" do
    setup do
      user = create_user()
      %{user: user, game: create_game(user)}
    end

    test "web", %{game: game} do
      {:ok, connection} =
        Games.create_connection(game, %{type: "web", url: "http://example.com/play"}, &connection_hook/1)

      {:ok, connection} = Games.update_connection(connection, %{url: "http://example.com/"}, &connection_hook/1)

      assert connection.url == "http://example.com/"
    end

    test "telnet", %{game: game} do
      {:ok, connection} =
        Games.create_connection(game, %{type: "telnet", host: "example.com", port: 4000}, &connection_hook/1)

      {:ok, connection} = Games.update_connection(connection, %{host: "game.example.com"}, &connection_hook/1)

      assert connection.host == "game.example.com"
    end

    test "secure telnet", %{game: game} do
      {:ok, connection} =
        Games.create_connection(game, %{type: "secure telnet", host: "example.com", port: 4000}, &connection_hook/1)

      {:ok, connection} = Games.update_connection(connection, %{host: "game.example.com"}, &connection_hook/1)

      assert connection.host == "game.example.com"
    end
  end

  describe "delete a connection" do
    setup do
      user = create_user()
      %{user: user, game: create_game(user)}
    end

    test "deletes it", %{game: game} do
      {:ok, connection} =
        Games.create_connection(game, %{type: "web", url: "http://example.com/play"}, &connection_hook/1)

      {:ok, _connection} = Games.delete_connection(connection)
    end
  end

  describe "marking a connection's mssp status" do
    setup do
      user = create_user()
      %{user: user, game: create_game(user)}
    end

    test "with mssp", %{game: game} do
      {:ok, connection} =
        Games.create_connection(game, %{type: "web", url: "http://example.com/play"}, &connection_hook/1)

      {:ok, connection} = Games.connection_has_mssp(connection)

      assert connection.supports_mssp
    end

    test "marks the game as showing the player graph", %{game: game} do
      {:ok, connection} =
        Games.create_connection(game, %{type: "web", url: "http://example.com/play"}, &connection_hook/1)

      {:ok, connection} = Games.connection_has_mssp(connection)

      {:ok, game} = Games.get(connection.game_id)
      assert game.display_player_graph
    end

    test "without mssp", %{game: game} do
      {:ok, connection} =
        Games.create_connection(game, %{type: "web", url: "http://example.com/play"}, &connection_hook/1)

      {:ok, connection} = Games.connection_has_mssp(connection)
      {:ok, alert} = Games.connection_has_no_mssp(connection)

      assert alert.title == "MSSP failed"
    end

    test "known without mssp", %{game: game} do
      {:ok, connection} =
        Games.create_connection(game, %{type: "web", url: "http://example.com/play"}, &connection_hook/1)

      :ok = Games.connection_has_no_mssp(connection)
    end
  end

  describe "checking a redirect_uri matches a user" do
    setup do
      user = create_user()
      %{user: user, game: create_game(user)}
    end

    test "is owned", %{user: user, game: game} do
      {:ok, redirect_uri} = Games.create_redirect_uri(game, "https://example.com/callback")

      assert Games.user_owns_redirect_uri?(user, redirect_uri)
    end

    test "is not owned", %{game: game} do
      {:ok, redirect_uri} = Games.create_redirect_uri(game, "https://example.com/callback")

      user = create_user(%{username: "other", email: "other@example.com"})
      refute Games.user_owns_redirect_uri?(user, redirect_uri)
    end
  end

  describe "create a redirect uri" do
    setup do
      user = create_user()
      %{user: user, game: create_game(user)}
    end

    test "successfully", %{game: game} do
      {:ok, redirect_uri} = Games.create_redirect_uri(game, "https://example.com/callback")
      assert redirect_uri.uri
    end
  end

  describe "delete a redirect uri" do
    setup do
      user = create_user()
      %{user: user, game: create_game(user)}
    end

    test "successfully", %{game: game} do
      {:ok, redirect_uri} = Games.create_redirect_uri(game, "https://example.com/callback")

      {:ok, redirect_uri} = Games.delete_redirect_uri(redirect_uri)

      refute Repo.get(Games.RedirectURI, redirect_uri.id)
    end
  end

  describe "seeing a game on telnet" do
    test "successfully" do
      game = create_game(create_user())

      {:ok, game} = Games.seen_on_telnet(game)

      assert game.telnet_last_seen_at
    end
  end

  describe "get a connection for the web client to use" do
    test "secure telnet" do
      game = create_game(create_user())
      secure_connection = create_connection(game, %{type: "secure telnet", host: "localhost", port: 5443})

      {:ok, connection} = Games.get_web_client_connection(game)

      assert connection.id == secure_connection.id
    end

    test "telnet" do
      game = create_game(create_user())
      telnet_connection = create_connection(game, %{type: "telnet", host: "localhost", port: 5555})

      {:ok, connection} = Games.get_web_client_connection(game)

      assert connection.id == telnet_connection.id
    end

    test "secure telnet is preferred" do
      game = create_game(create_user())
      secure_connection = create_connection(game, %{type: "secure telnet", host: "localhost", port: 5443})
      _telnet_connection = create_connection(game, %{type: "telnet", host: "localhost", port: 5555})

      {:ok, connection} = Games.get_web_client_connection(game)

      assert connection.id == secure_connection.id
    end

    test "no connections" do
      game = create_game(create_user())

      {:error, :not_found} = Games.get_web_client_connection(game)
    end
  end

  defp connection_hook(_connection), do: :ok
end
