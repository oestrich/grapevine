defmodule Socket.Handler.PlayersTest do
  use Grapevine.DataCase

  alias Socket.Presence
  alias Socket.Web.Router
  alias Socket.Web.State

  describe "player status" do
    setup [:basic_setup]

    test "new sign in", %{state: state} do
      state = %{state | supports: ["channels", "players"]}
      Web.Endpoint.subscribe("players:status")

      frame = %{
        "event" => "players/sign-in",
        "payload" => %{
          "name" => "Player"
        }
      }

      assert {:ok, :skip, state} = Router.receive(state, frame)
      assert state.players == ["Player"]
      assert_receive %{event: "players/sign-in"}, 50
    end

    test "new sign in - name required", %{state: state} do
      state = %{state | supports: ["channels", "players"]}
      Web.Endpoint.subscribe("players:status")

      frame = %{
        "event" => "players/sign-in",
        "ref" => "sign-in",
        "payload" => %{
          "name" => ""
        }
      }

      assert {:ok, response, state} = Router.receive(state, frame)
      assert state.players == []
      assert response["status"] == "failure"
    end

    test "new sign in - game marked as hidden", %{state: state} do
      game = %{state.game | display: false}
      state = %{state | game: game, supports: ["channels", "players"]}
      Web.Endpoint.subscribe("players:status")

      frame = %{
        "event" => "players/sign-in",
        "payload" => %{
          "name" => "Player"
        }
      }

      assert {:ok, :skip, state} = Router.receive(state, frame)
      assert state.players == ["Player"]
      refute_receive %{event: "players/sign-in"}, 50
    end

    test "new sign in - game players are hidden", %{state: state} do
      game = %{state.game | display_players: false}
      state = %{state | game: game, supports: ["channels", "players"]}
      Web.Endpoint.subscribe("players:status")

      frame = %{
        "event" => "players/sign-in",
        "payload" => %{
          "name" => "Player"
        }
      }

      assert {:ok, :skip, state} = Router.receive(state, frame)
      assert state.players == ["Player"]
      refute_receive %{event: "players/sign-in"}, 50
    end

    test "new sign in - already signed in, no event", %{state: state} do
      state = %{state | supports: ["channels", "players"], players: ["Player"]}
      Web.Endpoint.subscribe("players:status")

      frame = %{
        "event" => "players/sign-in",
        "payload" => %{
          "name" => "Player"
        }
      }

      assert {:ok, :skip, state} = Router.receive(state, frame)
      assert state.players == ["Player"]
      refute_receive %{event: "players/sign-in"}, 50
    end

    test "new sign in - must send a player name", %{state: state} do
      state = %{state | supports: ["channels", "players"]}
      Web.Endpoint.subscribe("players:status")

      frame = %{
        "event" => "players/sign-in",
        "payload" => %{}
      }

      assert {:ok, :skip, _state} = Router.receive(state, frame)

      refute_receive %{event: "players/sign-in"}, 50
    end

    test "sign out", %{state: state} do
      state = %{state | supports: ["channels", "players"], players: ["Player"]}

      Web.Endpoint.subscribe("players:status")

      frame = %{
        "event" => "players/sign-out",
        "payload" => %{
          "name" => "Player"
        }
      }

      assert {:ok, :skip, state} = Router.receive(state, frame)
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
          "name" => "Player"
        }
      }

      assert {:ok, :skip, state} = Router.receive(state, frame)
      assert state.players == []
      refute_receive %{event: "players/sign-out"}, 50
    end

    test "sign out - game players are hidden", %{state: state} do
      game = %{state.game | display_players: false}
      state = %{state | game: game, supports: ["channels", "players"], players: ["Player"]}

      Web.Endpoint.subscribe("players:status")

      frame = %{
        "event" => "players/sign-out",
        "payload" => %{
          "name" => "Player"
        }
      }

      assert {:ok, :skip, state} = Router.receive(state, frame)
      assert state.players == []
      refute_receive %{event: "players/sign-out"}, 50
    end

    test "sign out - player is not in the known list", %{state: state} do
      state = %{state | supports: ["channels", "players"]}

      Web.Endpoint.subscribe("players:status")

      frame = %{
        "event" => "players/sign-out",
        "payload" => %{
          "name" => "Player"
        }
      }

      assert {:ok, :skip, state} = Router.receive(state, frame)
      assert state.players == []
      refute_receive %{event: "players/sign-out"}, 50
    end

    test "does not support the players feature - no ref", %{state: state} do
      frame = %{
        "event" => "players/sign-out",
        "payload" => %{
          "name" => "Player"
        }
      }

      assert {:ok, :skip, _state} = Router.receive(state, frame)
    end

    test "does not support the players feature - ref", %{state: state} do
      frame = %{
        "event" => "players/sign-out",
        "ref" => "ref",
        "payload" => %{
          "name" => "Player"
        }
      }

      assert {:ok, response, _state} = Router.receive(state, frame)

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

      assert {:ok, :skip, _state} = Router.receive(state, frame)

      game_name = game.short_name

      refute_receive {:broadcast,
                      %{"event" => "players/status", "payload" => %{"game" => ^game_name}}},
                     50

      assert_receive {:broadcast,
                      %{"event" => "players/status", "payload" => %{"game" => "EVOne"}}},
                     50

      assert_receive {:broadcast,
                      %{"event" => "players/status", "payload" => %{"game" => "EVTwo"}}},
                     50

      refute_receive {:broadcast,
                      %{"event" => "players/status", "payload" => %{"game" => "EVThree"}}},
                     50
    end

    test "request game status updates for a single game", %{state: state} do
      frame = %{
        "event" => "players/status",
        "ref" => UUID.uuid4(),
        "payload" => %{
          "game" => "EVTwo"
        }
      }

      assert {:ok, :skip, _state} = Router.receive(state, frame)

      refute_receive {:broadcast,
                      %{"event" => "players/status", "payload" => %{"game" => "EVOne"}}},
                     50

      assert_receive {:broadcast,
                      %{"event" => "players/status", "payload" => %{"game" => "EVTwo"}}},
                     50
    end
  end

  def basic_setup(_) do
    user = create_user()
    game = create_game(user)

    Presence.reset()

    state = %State{
      status: "active",
      supports: ["channels"],
      players: [],
      game: game
    }

    %{state: state, user: user, game: game}
  end

  def status_updates(%{state: state, user: user, game: game1}) do
    state = %{state | supports: ["channels", "players"]}

    game2 = create_game(user, %{name: "ExVenture 1", short_name: "EVOne"})
    game3 = create_game(user, %{name: "ExVenture 2", short_name: "EVTwo"})
    game4 = create_game(user, %{name: "ExVenture 3", short_name: "EVThree", display: false})

    Presence.update_game(presence_state(game1, %{players: ["Player1"]}))
    Presence.update_game(presence_state(game2, %{players: ["Player2"]}))
    Presence.update_game(presence_state(game3, %{players: ["Player3"]}))
    Presence.update_game(presence_state(game4, %{players: ["Player4"]}))

    %{state: state}
  end
end
