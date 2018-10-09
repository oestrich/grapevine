defmodule Web.Socket.ImplementationTest do
  use Gossip.DataCase

  alias Gossip.Presence
  alias Web.Socket.Implementation

  describe "authenticating" do
    setup do
      %{state: %{status: "inactive"}, game: create_game(create_user())}
    end

    test "validating authentication", %{state: state, game: game} do
      frame = %{
        "event" => "authenticate",
        "payload" => %{
          "client_id" => game.client_id,
          "client_secret" => game.client_secret,
          "supports" => ["channels"],
          "channels" => ["gossip"],
          "players" => ["player"],
        },
      }

      {:ok, response, state} = Implementation.receive(state, frame)

      assert response.status == "success"

      assert state.status == "active"
      assert state.game.id == game.id
      assert state.players == ["player"]
    end

    test "invalid credentials", %{state: state, game: game} do
      frame = %{
        "event" => "authenticate",
        "payload" => %{
          "client_id" => game.client_id,
          "client_secret" => "bad",
          "supports" => ["channels"],
        },
      }

      {:disconnect, response, state} = Implementation.receive(state, frame)

      assert response.status == "failure"
      assert state.status == "inactive"
    end

    test "no supports in the payload", %{state: state, game: game} do
      frame = %{
        "event" => "authenticate",
        "payload" => %{
          "client_id" => game.client_id,
          "client_secret" => game.client_secret,
        },
      }

      {:disconnect, response, state} = Implementation.receive(state, frame)

      assert response.status == "failure"
      assert state.status == "inactive"
    end

    test "must support channels", %{state: state, game: game} do
      frame = %{
        "event" => "authenticate",
        "payload" => %{
          "client_id" => game.client_id,
          "client_secret" => game.client_secret,
          "supports" => [],
        },
      }

      {:disconnect, response, state} = Implementation.receive(state, frame)

      assert response.status == "failure"
      assert state.status == "inactive"
    end

    test "trying to support something non-existant", %{state: state, game: game} do
      frame = %{
        "event" => "authenticate",
        "payload" => %{
          "client_id" => game.client_id,
          "client_secret" => game.client_secret,
          "supports" => ["channels", "other"],
        },
      }

      {:disconnect, response, state} = Implementation.receive(state, frame)

      assert response.status == "failure"
      assert state.status == "inactive"
    end

    test "subscribing to an invalid channel name", %{state: state, game: game} do
      frame = %{
        "event" => "authenticate",
        "payload" => %{
          "client_id" => game.client_id,
          "client_secret" => game.client_secret,
          "supports" => ["channels"],
          "channels" => ["this is bad"],
        },
      }

      {:ok, response, _state} = Implementation.receive(state, frame)

      assert response.status == "success"

      assert_receive {:broadcast, %{error: ~s(Could not subscribe to 'this is bad')}}
    end

    test "validating as an application", %{state: state} do
      application = create_application()

      frame = %{
        "event" => "authenticate",
        "payload" => %{
          "client_id" => application.client_id,
          "client_secret" => application.client_secret,
          "supports" => ["channels"],
        },
      }

      {:ok, response, state} = Implementation.receive(state, frame)

      assert response.status == "success"

      assert state.status == "active"
      assert state.game.id == application.id
    end

    test "invalid application credentials", %{state: state} do
      application = create_application()

      frame = %{
        "event" => "authenticate",
        "payload" => %{
          "client_id" => application.client_id,
          "client_secret" => "bad secret",
          "supports" => ["channels"],
        },
      }

      {:disconnect, response, state} = Implementation.receive(state, frame)

      assert response.status == "failure"
      assert state.status == "inactive"
    end
  end

  describe "post a new message" do
    setup do
      user = create_user()
      game = create_game(user)

      state = %{
        status: "active",
        game: game,
        channels: ["gossip"],
      }

      %{state: state, game: game}
    end

    test "broadcasts the message", %{state: state, game: game} do
      Web.Endpoint.subscribe("channels:gossip")

      frame = %{
        "event" => "channels/send",
        "payload" => %{
          "channel" => "gossip",
          "name" => "Player",
          "message" => "Hello!",
        },
      }

      assert {:ok, :skip, _state} = Implementation.receive(state, frame)

      game_name = game.short_name
      assert_receive %{payload: %{"channel" => "gossip", "game" => ^game_name}}
    end

    test "strips out mxp data", %{state: state} do
      Web.Endpoint.subscribe("channels:gossip")

      frame = %{
        "event" => "channels/send",
        "payload" => %{
          "channel" => "gossip",
          "name" => "Player",
          "message" => "<b>Hello!</b>",
        },
      }

      assert {:ok, :skip, _state} = Implementation.receive(state, frame)

      assert_receive %{payload: %{"channel" => "gossip", "message" => "Hello!"}}
    end

    test "does not broadcast the message if you are not subscribed", %{state: state, game: game} do
      Web.Endpoint.subscribe("channels:gossip")

      frame = %{
        "event" => "channels/send",
        "payload" => %{
          "channel" => "general",
          "name" => "Player",
          "message" => "Hello!",
        },
      }

      assert {:ok, :skip, _state} = Implementation.receive(state, frame)

      game_name = game.short_name
      refute_receive %{payload: %{"channel" => "gossip", "game" => ^game_name}}, 50
    end
  end

  describe "changing subscriptions" do
    setup do
      user = create_user()
      game = create_game(user)

      state = %{
        status: "active",
        game: game,
        channels: ["gossip"],
      }

      %{state: state, game: game}
    end

    test "subscribe to a new channel", %{state: state} do
      frame = %{
        "event" => "channels/subscribe",
        "payload" => %{
          "channel" => "general",
        },
      }

      assert {:ok, :skip, state} = Implementation.receive(state, frame)
      assert state.channels == ["general", "gossip"]
    end

    test "subscribe to a new channel - failure", %{state: state} do
      frame = %{
        "event" => "channels/subscribe",
        "payload" => %{
          "channel" => "bad channel",
        },
      }

      assert {:ok, response, state} = Implementation.receive(state, frame)

      assert state.channels == ["gossip"]
      assert response.error == "Could not subscribe to 'bad channel'"
    end

    test "unsubscribe to a channel", %{state: state} do
      frame = %{
        "event" => "channels/unsubscribe",
        "payload" => %{
          "channel" => "gossip",
        },
      }

      assert {:ok, :skip, state} = Implementation.receive(state, frame)
      assert state.channels == []
    end
  end

  describe "heartbeats" do
    setup [:basic_setup]

    test "sending heartbeats", %{state: state} do
      {:ok, response, state} = Implementation.heartbeat(state)

      assert response == %{event: "heartbeat"}
      assert state.heartbeat_count == 1
    end

    test "sending heartbeats - out of counts", %{state: state} do
      state = %{state | heartbeat_count: 3}
      assert {:disconnect, _state} = Implementation.heartbeat(state)
    end

    test "receive a heartbeat", %{state: state} do
      frame = %{
        "event" => "heartbeat",
        "payload" => %{
          "players" => ["player"],
        },
      }

      {:ok, state} = Implementation.receive(state, frame)

      assert state.heartbeat_count == 0
      assert state.players == ["player"]
    end
  end

  describe "player status" do
    setup [:basic_setup]

    test "new sign in", %{state: state} do
      state = %{state | supports: ["channels", "players"]}
      Web.Endpoint.subscribe("players:status")

      frame = %{
        "event" => "players/sign-in",
        "payload" => %{
          "name" => "Player",
        },
      }

      assert {:ok, :skip, state} = Implementation.receive(state, frame)
      assert state.players == ["Player"]
      assert_receive %{event: "players/sign-in"}, 50
    end

    test "new sign in - game marked as hidden", %{state: state} do
      game = %{state.game | display: false}
      state = %{state | game: game, supports: ["channels", "players"]}
      Web.Endpoint.subscribe("players:status")

      frame = %{
        "event" => "players/sign-in",
        "payload" => %{
          "name" => "Player",
        },
      }

      assert {:ok, :skip, state} = Implementation.receive(state, frame)
      assert state.players == ["Player"]
      refute_receive %{event: "players/sign-in"}, 50
    end

    test "new sign in - already signed in, no event", %{state: state} do
      state = %{state | supports: ["channels", "players"], players: ["Player"]}
      Web.Endpoint.subscribe("players:status")

      frame = %{
        "event" => "players/sign-in",
        "payload" => %{
          "name" => "Player",
        },
      }

      assert {:ok, :skip, state} = Implementation.receive(state, frame)
      assert state.players == ["Player"]
      refute_receive %{event: "players/sign-in"}, 50
    end

    test "new sign in - must send a player name", %{state: state} do
      state = %{state | supports: ["channels", "players"]}
      Web.Endpoint.subscribe("players:status")

      frame = %{
        "event" => "players/sign-in",
        "payload" => %{},
      }

      assert {:ok, :skip, _state} = Implementation.receive(state, frame)

      refute_receive %{event: "players/sign-in"}, 50
    end

    test "sign out", %{state: state} do
      state = %{state | supports: ["channels", "players"], players: ["Player"]}

      Web.Endpoint.subscribe("players:status")

      frame = %{
        "event" => "players/sign-out",
        "payload" => %{
          "name" => "Player",
        },
      }

      assert {:ok, :skip, state} = Implementation.receive(state, frame)
      assert state.players == []
      assert_receive %{event: "players/sign-out"}, 50
    end

    test "sign out - game is marked as hidden", %{state: state} do
      game = %{state.game | display: false}
      state = %{state | game: game, supports: ["channels", "players"], players: ["Player"]}

      Web.Endpoint.subscribe("players:status")

      frame = %{
        "event" => "players/sign-out",
        "payload" => %{
          "name" => "Player",
        },
      }

      assert {:ok, :skip, state} = Implementation.receive(state, frame)
      assert state.players == []
      refute_receive %{event: "players/sign-out"}, 50
    end

    test "sign out - player is not in the known list", %{state: state} do
      state = %{state | supports: ["channels", "players"]}

      Web.Endpoint.subscribe("players:status")

      frame = %{
        "event" => "players/sign-out",
        "payload" => %{
          "name" => "Player",
        },
      }

      assert {:ok, :skip, state} = Implementation.receive(state, frame)
      assert state.players == []
      refute_receive %{event: "players/sign-out"}, 50
    end

    test "does not support the players feature - no ref", %{state: state} do
      frame = %{
        "event" => "players/sign-out",
        "payload" => %{
          "name" => "Player",
        },
      }

      assert {:ok, :skip, _state} = Implementation.receive(state, frame)
    end

    test "does not support the players feature - ref", %{state: state} do
      frame = %{
        "event" => "players/sign-out",
        "ref" => "ref",
        "payload" => %{
          "name" => "Player",
        },
      }

      assert {:ok, response, _state} = Implementation.receive(state, frame)

      assert response["ref"] == "ref"
      assert response["status"] == "failure"
    end
  end

  describe "player status udpates" do
    setup [:basic_setup, :status_updates]

    test "fetch all updates", %{state: state, game: game} do
      frame = %{
        "event" => "players/status",
        "ref" => UUID.uuid4()
      }

      assert {:ok, :skip, _state} = Implementation.receive(state, frame)

      game_name = game.short_name
      refute_receive {:broadcast, %{"event" => "players/status", "payload" => %{"game" => ^game_name}}}, 50
      assert_receive {:broadcast, %{"event" => "players/status", "payload" => %{"game" => "EVOne"}}}, 50
      assert_receive {:broadcast, %{"event" => "players/status", "payload" => %{"game" => "EVTwo"}}}, 50
      refute_receive {:broadcast, %{"event" => "players/status", "payload" => %{"game" => "EVThree"}}}, 50
    end

    test "request game status updates for a single game", %{state: state} do
      frame = %{
        "event" => "players/status",
        "ref" => UUID.uuid4(),
        "payload" => %{
          "game" => "EVTwo",
        }
      }

      assert {:ok, :skip, _state} = Implementation.receive(state, frame)

      refute_receive {:broadcast, %{"event" => "players/status", "payload" => %{"game" => "EVOne"}}}, 50
      assert_receive {:broadcast, %{"event" => "players/status", "payload" => %{"game" => "EVTwo"}}}, 50
    end
  end

  describe "tells" do
    setup [:basic_setup]

    test "send a new tell", %{state: state, user: user} do
      state = %{state | supports: ["channels", "tells"]}

      game = create_game(user, %{name: "ExVenture 1", short_name: "EVOne"})
      Presence.update_game(game, ["tells"], ["Player1"])
      Web.Endpoint.subscribe("tells:#{game.short_name}")

      frame = %{
        "event" => "tells/send",
        "ref" => "ref",
        "payload" => %{
          "from_name" => "Player",
          "to_game" => "EVOne",
          "to_name" => "Player1",
          "sent_at" => "2018-07-17T13:12:28Z",
          "message" => "hi"
        },
      }

      assert {:ok, %{"ref" => "ref"}, _state} = Implementation.receive(state, frame)
      assert_receive %{event: "tells/receive"}, 50
    end

    test "handles short names not capitalized", %{state: state, user: user} do
      state = %{state | supports: ["channels", "tells"]}

      game = create_game(user, %{name: "ExVenture 1", short_name: "EVOne"})
      Presence.update_game(game, ["tells"], ["Player1"])
      Web.Endpoint.subscribe("tells:#{game.short_name}")

      frame = %{
        "event" => "tells/send",
        "ref" => "ref",
        "payload" => %{
          "from_name" => "Player",
          "to_game" => "evone",
          "to_name" => "Player1",
          "sent_at" => "2018-07-17T13:12:28Z",
          "message" => "hi"
        },
      }

      assert {:ok, %{"ref" => "ref"}, _state} = Implementation.receive(state, frame)
      assert_receive %{event: "tells/receive"}, 50
    end

    test "handles player name not capitalized", %{state: state, user: user} do
      state = %{state | supports: ["channels", "tells"]}

      game = create_game(user, %{name: "ExVenture 1", short_name: "EVOne"})
      Presence.update_game(game, ["tells"], ["Player1"])
      Web.Endpoint.subscribe("tells:#{game.short_name}")

      frame = %{
        "event" => "tells/send",
        "ref" => "ref",
        "payload" => %{
          "from_name" => "Player",
          "to_game" => "EVOne",
          "to_name" => "player1",
          "sent_at" => "2018-07-17T13:12:28Z",
          "message" => "hi"
        },
      }

      assert {:ok, %{"ref" => "ref"}, _state} = Implementation.receive(state, frame)
      assert_receive %{event: "tells/receive"}, 50
    end

    test "validation problem with the tell", %{state: state} do
      state = %{state | supports: ["channels", "tells"]}

      frame = %{
        "event" => "tells/send",
        "ref" => "ref",
        "payload" => %{
          "from_name" => "Player",
          "sent_at" => "2018-07-17T13:12:28Z",
          "message" => "hi"
        },
      }

      assert {:ok, response, _state} = Implementation.receive(state, frame)
      assert response["ref"] == "ref"
      assert response["status"] == "failure"
    end

    test "receiving game is offline", %{state: state} do
      state = %{state | supports: ["channels", "tells"]}

      frame = %{
        "event" => "tells/send",
        "ref" => "ref",
        "payload" => %{
          "from_name" => "Player",
          "to_game" => "ExVenture",
          "to_name" => "eric",
          "sent_at" => "2018-07-17T13:12:28Z",
          "message" => "hi"
        },
      }

      assert {:ok, response, _state} = Implementation.receive(state, frame)
      assert response["ref"] == "ref"
      assert response["error"] == "game offline"
    end

    test "receiving player is offline", %{state: state, user: user} do
      state = %{state | supports: ["channels", "tells"]}

      game = create_game(user, %{name: "ExVenture 1", short_name: "EVOne"})
      Presence.update_game(game, ["tells"], ["Player1"])

      frame = %{
        "event" => "tells/send",
        "ref" => "ref",
        "payload" => %{
          "from_name" => "Player",
          "to_game" => "EVOne",
          "to_name" => "eric",
          "sent_at" => "2018-07-17T13:12:28Z",
          "message" => "hi"
        },
      }

      assert {:ok, response, _state} = Implementation.receive(state, frame)
      assert response["ref"] == "ref"
      assert response["error"] == "player offline"
    end

    test "receiving game does not support tells", %{state: state, user: user} do
      state = %{state | supports: ["channels", "tells"]}

      game = create_game(user, %{name: "ExVenture 1", short_name: "EVOne"})
      Presence.update_game(game, [], ["Player1"])

      frame = %{
        "event" => "tells/send",
        "ref" => "ref",
        "payload" => %{
          "from_name" => "Player",
          "to_game" => "EVOne",
          "to_name" => "eric",
          "sent_at" => "2018-07-17T13:12:28Z",
          "message" => "hi"
        },
      }

      assert {:ok, response, _state} = Implementation.receive(state, frame)
      assert response["ref"] == "ref"
      assert response["error"] == "not supported"
    end

    test "does not support the tells feature - no ref", %{state: state} do
      frame = %{
        "event" => "tells/send",
        "payload" => %{
          "from_name" => "Player",
          "to_game" => "ExVenture",
          "to_name" => "eric",
          "sent_at" => "2018-07-17T13:12:28Z",
          "message" => "hi"
        },
      }

      assert {:ok, :skip, _state} = Implementation.receive(state, frame)
    end

    test "does not support the tells feature - ref", %{state: state} do
      frame = %{
        "event" => "tells/send",
        "ref" => "ref",
        "payload" => %{
          "from_name" => "Player",
          "to_game" => "ExVenture",
          "to_name" => "eric",
          "sent_at" => "2018-07-17T13:12:28Z",
          "message" => "hi"
        },
      }

      assert {:ok, response, _state} = Implementation.receive(state, frame)

      assert response["ref"] == "ref"
      assert response["status"] == "failure"
    end
  end

  describe "games" do
    setup [:basic_setup, :status_updates]

    test "fetch all updates", %{state: state, game: game} do
      state = %{state | supports: ["channels", "games"]}

      frame = %{
        "event" => "games/status",
        "ref" => UUID.uuid4()
      }

      assert {:ok, :skip, _state} = Implementation.receive(state, frame)

      game_name = game.short_name
      refute_receive {:broadcast, %{"event" => "games/status", "payload" => %{game: ^game_name}}}, 50
      assert_receive {:broadcast, %{"event" => "games/status", "payload" => %{game: "EVOne"}}}, 50
      assert_receive {:broadcast, %{"event" => "games/status", "payload" => %{game: "EVTwo"}}}, 50
      refute_receive {:broadcast, %{"event" => "games/status", "payload" => %{game: "EVThree"}}}, 50
    end

    test "does not support the games feature - ref", %{state: state} do
      frame = %{
        "event" => "games/status",
        "ref" => "ref"
      }

      assert {:ok, response, _state} = Implementation.receive(state, frame)

      assert response["ref"] == "ref"
      assert response["status"] == "failure"
    end

    test "request game status updates for a single game", %{state: state} do
      state = %{state | supports: ["channels", "games"]}

      frame = %{
        "event" => "games/status",
        "ref" => UUID.uuid4(),
        "payload" => %{
          "game" => "EVTwo",
        }
      }

      assert {:ok, :skip, _state} = Implementation.receive(state, frame)

      refute_receive {:broadcast, %{"event" => "games/status", "payload" => %{game: "EVOne"}}}, 50
      assert_receive {:broadcast, %{"event" => "games/status", "payload" => %{game: "EVTwo"}}}, 50
    end
  end

  describe "available supports" do
    test "channels is valid" do
      assert Implementation.valid_support?("channels")
    end

    test "players is valid" do
      assert Implementation.valid_support?("players")
    end

    test "tells is valid" do
      assert Implementation.valid_support?("tells")
    end

    test "games is valid" do
      assert Implementation.valid_support?("games")
    end
  end

  def basic_setup(_) do
    user = create_user()
    game = create_game(user)

    Presence.reset()

    state = %Web.Socket.State{
      status: "active",
      supports: ["channels"],
      players: [],
      game: game,
    }

    %{state: state, user: user, game: game}
  end

  def status_updates(%{state: state, user: user, game: game1}) do
    state = %{state | supports: ["channels", "players"]}

    game2 = create_game(user, %{name: "ExVenture 1", short_name: "EVOne"})
    game3 = create_game(user, %{name: "ExVenture 2", short_name: "EVTwo"})
    game4 = create_game(user, %{name: "ExVenture 3", short_name: "EVThree", display: false})

    Presence.update_game(game1, [], ["Player1"])
    Presence.update_game(game2, [], ["Player2"])
    Presence.update_game(game3, [], ["Player3"])
    Presence.update_game(game4, [], ["Player4"])

    %{state: state}
  end
end
