defmodule Socket.Handler.CoreTest do
  use Grapevine.DataCase

  alias Socket.Handler.Core
  alias Socket.Handler.Core.Heartbeat
  alias Socket.Presence
  alias Socket.RateLimit
  alias Socket.Web.Router
  alias Socket.Web.State

  describe "authenticating" do
    setup do
      %{state: %State{status: "inactive"}, game: create_game(create_user())}
    end

    test "validating authentication", %{state: state, game: game} do
      frame = %{
        "event" => "authenticate",
        "payload" => %{
          "client_id" => game.client_id,
          "client_secret" => game.client_secret,
          "supports" => ["channels"],
          "channels" => ["grapevine"],
          "players" => ["player"]
        }
      }

      {:ok, response, state} = Router.receive(state, frame)

      assert response.status == "success"

      assert state.status == "active"
      assert state.game.id == game.id
      assert state.players == ["player"]
    after
      Presence.reset()
    end

    test "invalid credentials", %{state: state, game: game} do
      frame = %{
        "event" => "authenticate",
        "payload" => %{
          "client_id" => game.client_id,
          "client_secret" => "bad",
          "supports" => ["channels"]
        }
      }

      {:disconnect, response, state} = Router.receive(state, frame)

      assert response.status == "failure"
      assert state.status == "inactive"
    end

    test "no supports in the payload", %{state: state, game: game} do
      frame = %{
        "event" => "authenticate",
        "payload" => %{
          "client_id" => game.client_id,
          "client_secret" => game.client_secret
        }
      }

      {:disconnect, response, state} = Router.receive(state, frame)

      assert response.status == "failure"
      assert state.status == "inactive"
    end

    test "must support channels", %{state: state, game: game} do
      frame = %{
        "event" => "authenticate",
        "payload" => %{
          "client_id" => game.client_id,
          "client_secret" => game.client_secret,
          "supports" => []
        }
      }

      {:disconnect, response, state} = Router.receive(state, frame)

      assert response.status == "failure"
      assert state.status == "inactive"
    end

    test "trying to support something non-existant", %{state: state, game: game} do
      frame = %{
        "event" => "authenticate",
        "payload" => %{
          "client_id" => game.client_id,
          "client_secret" => game.client_secret,
          "supports" => ["channels", "other"]
        }
      }

      {:disconnect, response, state} = Router.receive(state, frame)

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
          "channels" => ["this is bad"]
        }
      }

      {:ok, response, _state} = Router.receive(state, frame)

      assert response.status == "success"

      assert_receive {:broadcast, %{error: ~s(Could not subscribe to 'this is bad')}}
    after
      Presence.reset()
    end

    test "trying to support tells with player display off", %{state: state, game: game} do
      game |> Ecto.Changeset.change(%{display_players: false}) |> Repo.update()

      frame = %{
        "event" => "authenticate",
        "payload" => %{
          "client_id" => game.client_id,
          "client_secret" => game.client_secret,
          "supports" => ["channels", "tells"],
          "channels" => []
        }
      }

      {:ok, response, _state} = Router.receive(state, frame)

      assert response.status == "success"

      assert [_, %{supports: ["channels"]}] = Presence.online_games()
    after
      Presence.reset()
    end
  end

  describe "heartbeats" do
    setup [:basic_setup]

    test "sending heartbeats", %{state: state} do
      {:ok, response, state} = Heartbeat.handle(state)

      assert response == %{event: "heartbeat"}
      assert state.heartbeat_count == 1
    end

    test "sending heartbeats - out of counts", %{state: state} do
      state = %{state | heartbeat_count: 3}
      assert {:disconnect, _state} = Heartbeat.handle(state)
    end

    test "receive a heartbeat", %{state: state} do
      frame = %{
        "event" => "heartbeat",
        "payload" => %{
          "players" => ["player"]
        }
      }

      {:ok, :skip, state} = Router.receive(state, frame)

      assert state.heartbeat_count == 0
      assert state.players == ["player"]
    end

    test "heartbeat filters out empty player names", %{state: state} do
      frame = %{
        "event" => "heartbeat",
        "payload" => %{
          "players" => ["player", ""]
        }
      }

      {:ok, :skip, state} = Router.receive(state, frame)

      assert state.heartbeat_count == 0
      assert state.players == ["player"]
    end
  end

  describe "post a new message" do
    setup do
      user = create_user()
      game = create_game(user)

      state = %State{
        status: "active",
        supports: ["channels"],
        game: game,
        channels: ["grapevine"],
        rate_limits: %{
          "channels/send" => %RateLimit{}
        }
      }

      %{state: state, game: game}
    end

    test "broadcasts the message", %{state: state, game: game} do
      Web.Endpoint.subscribe("channels:grapevine")

      frame = %{
        "event" => "channels/send",
        "payload" => %{
          "channel" => "grapevine",
          "name" => "Player",
          "message" => "Hello!"
        }
      }

      assert {:ok, :skip, _state} = Router.receive(state, frame)

      game_name = game.short_name
      assert_receive %{payload: %{"channel" => "grapevine", "game" => ^game_name}}
    end

    test "strips out mxp data", %{state: state} do
      Web.Endpoint.subscribe("channels:grapevine")

      frame = %{
        "event" => "channels/send",
        "payload" => %{
          "channel" => "grapevine",
          "name" => "Player",
          "message" => "<b>Hello!</b>"
        }
      }

      assert {:ok, :skip, _state} = Router.receive(state, frame)

      assert_receive %{payload: %{"channel" => "grapevine", "message" => "Hello!"}}
    end

    test "does not broadcast the message if you are not subscribed", %{state: state, game: game} do
      Web.Endpoint.subscribe("channels:grapevine")

      frame = %{
        "event" => "channels/send",
        "payload" => %{
          "channel" => "general",
          "name" => "Player",
          "message" => "Hello!"
        }
      }

      assert {:ok, :skip, _state} = Router.receive(state, frame)

      game_name = game.short_name
      refute_receive %{payload: %{"channel" => "grapevine", "game" => ^game_name}}, 50
    end

    test "records the message", %{state: state} do
      {:ok, :skip, _state} =
        Router.receive(state, %{
          "event" => "channels/send",
          "payload" => %{
            "channel" => "grapevine",
            "name" => "Player",
            "message" => "Hello!"
          }
        })

      assert length(Repo.all(GrapevineData.Messages.Message)) == 1
    end

    test "records current rate of send", %{state: state} do
      {:ok, :skip, state} =
        Router.receive(state, %{
          "event" => "channels/send",
          "payload" => %{
            "channel" => "grapevine",
            "name" => "Player",
            "message" => "Hello!"
          }
        })

      rate_limit = state.rate_limits["channels/send"]
      assert rate_limit.current == 1
      assert rate_limit.last_sent_at
    end

    test "prevents going over your rate", %{state: state} do
      rate_limit = %RateLimit{current: 10, limit: 10}
      rate_limits = Map.put(state.rate_limits, "channels/send", rate_limit)
      state = Map.put(state, :rate_limits, rate_limits)

      {:ok, response, _state} =
        Router.receive(state, %{
          "event" => "channels/send",
          "ref" => "channels/send",
          "payload" => %{
            "channel" => "grapevine",
            "name" => "Player",
            "message" => "Hello!"
          }
        })

      assert response["error"] == "rate limit exceeded"
    end

    test "disconnects you if you get limited too often", %{state: state} do
      rate_limit = %RateLimit{current: 10, limit: 10, total_limited: 10}
      rate_limits = Map.put(state.rate_limits, "channels/send", rate_limit)
      state = Map.put(state, :rate_limits, rate_limits)

      {:disconnect, response, _state} =
        Router.receive(state, %{
          "event" => "channels/send",
          "ref" => "channels/send",
          "payload" => %{
            "channel" => "grapevine",
            "name" => "Player",
            "message" => "Hello!"
          }
        })

      assert response["error"] == "disconnected due to rate limit abuse"
    end
  end

  describe "subscribing" do
    setup do
      user = create_user()
      game = create_game(user)

      state = %State{
        status: "active",
        supports: ["channels"],
        game: game,
        channels: ["grapevine"],
        rate_limits: %{
          "channels/subscribe" => %RateLimit{}
        }
      }

      %{state: state, game: game}
    end

    test "subscribe to a new channel", %{state: state} do
      frame = %{
        "event" => "channels/subscribe",
        "payload" => %{
          "channel" => "general"
        }
      }

      assert {:ok, :skip, state} = Router.receive(state, frame)
      assert state.channels == ["general", "grapevine"]
    end

    test "subscribes only once", %{state: state} do
      frame = %{
        "event" => "channels/subscribe",
        "payload" => %{
          "channel" => "general"
        }
      }

      {:ok, :skip, state} = Router.receive(state, frame)
      {:ok, :skip, state} = Router.receive(state, frame)

      assert state.channels == ["general", "grapevine"]
    end

    test "subscribe to a new channel - failure", %{state: state} do
      frame = %{
        "event" => "channels/subscribe",
        "ref" => "123",
        "payload" => %{
          "channel" => "bad channel"
        }
      }

      assert {:ok, response, state} = Router.receive(state, frame)

      assert state.channels == ["grapevine"]
      assert response["error"] == ~s(Could not subscribe to "bad channel")
    end

    test "records current rate of subscribe", %{state: state} do
      frame = %{
        "event" => "channels/subscribe",
        "payload" => %{
          "channel" => "general"
        }
      }

      {:ok, :skip, state} = Router.receive(state, frame)

      rate_limit = state.rate_limits["channels/subscribe"]
      assert rate_limit.current == 1
      assert rate_limit.last_sent_at
    end
  end

  describe "unsubscribing" do
    setup do
      user = create_user()
      game = create_game(user)

      state = %State{
        status: "active",
        supports: ["channels"],
        game: game,
        channels: ["grapevine"],
        rate_limits: %{
          "channels/unsubscribe" => %RateLimit{}
        }
      }

      %{state: state, game: game}
    end

    test "unsubscribe to a channel", %{state: state} do
      frame = %{
        "event" => "channels/unsubscribe",
        "payload" => %{
          "channel" => "grapevine"
        }
      }

      assert {:ok, :skip, state} = Router.receive(state, frame)
      assert state.channels == []
    end

    test "unsubscribe to a channel you are not subscribed to", %{state: state} do
      frame = %{
        "event" => "channels/unsubscribe",
        "payload" => %{
          "channel" => "unknown"
        }
      }

      assert {:ok, :skip, state} = Router.receive(state, frame)
      assert state.channels == ["grapevine"]
    end

    test "unsubscribe to a channel, null channel", %{state: state} do
      frame = %{
        "event" => "channels/unsubscribe",
        "payload" => %{
          "channel" => nil
        }
      }

      assert {:ok, :skip, state} = Router.receive(state, frame)
      assert state.channels == ["grapevine"]
    end

    test "records current rate of unsubscribe", %{state: state} do
      frame = %{
        "event" => "channels/unsubscribe",
        "payload" => %{
          "channel" => "grapevine"
        }
      }

      {:ok, :skip, state} = Router.receive(state, frame)

      rate_limit = state.rate_limits["channels/unsubscribe"]
      assert rate_limit.current == 1
      assert rate_limit.last_sent_at
    end
  end

  describe "available supports" do
    test "channels is valid" do
      assert Core.valid_support?("channels")
    end

    test "players is valid" do
      assert Core.valid_support?("players")
    end

    test "tells is valid" do
      assert Core.valid_support?("tells")
    end

    test "games is valid" do
      assert Core.valid_support?("games")
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
end
