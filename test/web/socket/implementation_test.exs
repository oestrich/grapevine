defmodule Web.Socket.ImplementationTest do
  use Gossip.DataCase

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
        },
      }

      {:ok, response, state} = Implementation.receive(state, frame)

      assert response.status == "success"

      assert state.status == "active"
      assert state.game.id == game.id
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
        "event" => "messages/new",
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

    test "does not broadcast the message if you are not subscribed", %{state: state, game: game} do
      Web.Endpoint.subscribe("channels:gossip")

      frame = %{
        "event" => "messages/new",
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
    end
  end

  describe "available supports" do
    test "channels is valid" do
      assert Implementation.valid_support?("channels")
    end

    test "players is valid" do
      assert Implementation.valid_support?("players")
    end
  end

  def basic_setup(_) do
    user = create_user()
    game = create_game(user)

    state = %Web.Socket.State{
      status: "active",
      game: game,
    }

    %{state: state, game: game}
  end
end
