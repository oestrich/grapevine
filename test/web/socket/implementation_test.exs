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
        },
      }

      {:ok, response, state} = Implementation.receive(state, frame)

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

      assert {:ok, _state} = Implementation.receive(state, frame)

      game_name = game.short_name
      assert_receive %{payload: %{"channel" => "gossip", "game" => ^game_name}}
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
          "connected_users" => ["player"],
        },
      }

      {:ok, state} = Implementation.receive(state, frame)

      assert state.heartbeat_count == 0
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
