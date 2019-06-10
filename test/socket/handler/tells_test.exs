defmodule Socket.Handler.TellsTest do
  use Grapevine.DataCase

  alias Socket.Presence
  alias Socket.Web.Router
  alias Socket.Web.State
  alias Socket.Handler.Tells

  doctest Tells

  describe "tells" do
    setup [:basic_setup]

    test "send a new tell", %{state: state, user: user} do
      state = %{state | supports: ["channels", "tells"]}

      game = create_game(user, %{name: "ExVenture 1", short_name: "EVOne"})
      Presence.update_game(presence_state(game, %{supports: ["tells"], players: ["Player1"]}))
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
        }
      }

      assert {:ok, %{"ref" => "ref"}, _state} = Router.receive(state, frame)
      assert_receive %{event: "tells/receive"}, 50
    end

    test "handles short names not capitalized", %{state: state, user: user} do
      state = %{state | supports: ["channels", "tells"]}

      game = create_game(user, %{name: "ExVenture 1", short_name: "EVOne"})
      Presence.update_game(presence_state(game, %{supports: ["tells"], players: ["Player1"]}))
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
        }
      }

      assert {:ok, %{"ref" => "ref"}, _state} = Router.receive(state, frame)
      assert_receive %{event: "tells/receive"}, 50
    end

    test "handles player name not capitalized", %{state: state, user: user} do
      state = %{state | supports: ["channels", "tells"]}

      game = create_game(user, %{name: "ExVenture 1", short_name: "EVOne"})
      Presence.update_game(presence_state(game, %{supports: ["tells"], players: ["Player1"]}))
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
        }
      }

      assert {:ok, %{"ref" => "ref"}, _state} = Router.receive(state, frame)
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
        }
      }

      assert {:ok, response, _state} = Router.receive(state, frame)
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
        }
      }

      assert {:ok, response, _state} = Router.receive(state, frame)
      assert response["ref"] == "ref"
      assert response["error"] == "game offline"
    end

    test "sending player is offline", %{state: state, user: user} do
      state = %{state | supports: ["channels", "tells"]}

      game = create_game(user, %{name: "ExVenture 1", short_name: "EVOne"})
      Presence.update_game(presence_state(state.game, %{supports: ["tells"], players: []}))
      Presence.update_game(presence_state(game, %{supports: ["tells"], players: ["eric"]}))

      frame = %{
        "event" => "tells/send",
        "ref" => "ref",
        "payload" => %{
          "from_name" => "Player",
          "to_game" => "EVOne",
          "to_name" => "eric",
          "sent_at" => "2018-07-17T13:12:28Z",
          "message" => "hi"
        }
      }

      assert {:ok, response, _state} = Router.receive(state, frame)
      assert response["ref"] == "ref"
      assert response["error"] == "sending player offline"
    end

    test "receiving player is offline", %{state: state, user: user} do
      state = %{state | supports: ["channels", "tells"]}

      game = create_game(user, %{name: "ExVenture 1", short_name: "EVOne"})
      Presence.update_game(presence_state(game, %{supports: ["tells"], players: ["Player1"]}))

      frame = %{
        "event" => "tells/send",
        "ref" => "ref",
        "payload" => %{
          "from_name" => "Player",
          "to_game" => "EVOne",
          "to_name" => "eric",
          "sent_at" => "2018-07-17T13:12:28Z",
          "message" => "hi"
        }
      }

      assert {:ok, response, _state} = Router.receive(state, frame)
      assert response["ref"] == "ref"
      assert response["error"] == "receiving player offline"
    end

    test "receiving game does not support tells", %{state: state, user: user} do
      state = %{state | supports: ["channels", "tells"]}

      game = create_game(user, %{name: "ExVenture 1", short_name: "EVOne"})
      Presence.update_game(presence_state(game, %{supports: [], players: ["Player1"]}))

      frame = %{
        "event" => "tells/send",
        "ref" => "ref",
        "payload" => %{
          "from_name" => "Player",
          "to_game" => "EVOne",
          "to_name" => "eric",
          "sent_at" => "2018-07-17T13:12:28Z",
          "message" => "hi"
        }
      }

      assert {:ok, response, _state} = Router.receive(state, frame)
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
        }
      }

      assert {:ok, :skip, _state} = Router.receive(state, frame)
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
        }
      }

      assert {:ok, response, _state} = Router.receive(state, frame)

      assert response["ref"] == "ref"
      assert response["status"] == "failure"
    end
  end

  describe "validate a send payload" do
    test "all valid" do
      payload = %{
        "from_name" => "Player",
        "to_game" => "ExVenture",
        "to_name" => "eric",
        "sent_at" => "2018-07-17T13:12:28Z",
        "message" => "hi"
      }

      assert Tells.valid_payload?(payload)
    end

    test "missing fields" do
      payload = %{
        "from_name" => "Player",
        "sent_at" => "2018-07-17T13:12:28Z",
        "message" => "hi"
      }

      refute Tells.valid_payload?(payload)
    end

    test "all strings" do
      payload = %{
        "from_name" => 1,
        "to_game" => nil,
        "to_name" => "eric",
        "sent_at" => "2018-07-17T13:12:28Z",
        "message" => "hi"
      }

      refute Tells.valid_payload?(payload)
    end

    test "sent_at is formatted properly" do
      payload = %{
        "from_name" => "Player",
        "to_game" => "ExVenture",
        "to_name" => "eric",
        "sent_at" => "2018-07-17T13:12:28-0400",
        "message" => "hi"
      }

      refute Tells.valid_payload?(payload)
    end
  end

  def basic_setup(_) do
    user = create_user()
    game = create_game(user)

    Presence.reset()
    Presence.update_game(presence_state(game, %{supports: ["tells"], players: ["Player"]}))

    state = %State{
      status: "active",
      supports: ["channels"],
      players: [],
      game: game
    }

    %{state: state, user: user, game: game}
  end
end
