defmodule Socket.Handler.GamesTest do
  use Grapevine.DataCase

  alias Socket.Presence
  alias Socket.Web.Router
  alias Socket.Web.State

  describe "games" do
    setup [:basic_setup, :status_updates]

    test "fetch all updates", %{state: state, game: game} do
      state = %{state | supports: ["channels", "games"]}

      frame = %{
        "event" => "games/status",
        "ref" => UUID.uuid4()
      }

      assert {:ok, :skip, _state} = Router.receive(state, frame)

      game_name = game.short_name

      refute_receive {:broadcast, %{"event" => "games/status", "payload" => %{game: ^game_name}}},
                     50

      assert_receive {:broadcast, %{"event" => "games/status", "payload" => %{game: "EVOne"}}}, 50
      assert_receive {:broadcast, %{"event" => "games/status", "payload" => %{game: "EVTwo"}}}, 50

      refute_receive {:broadcast, %{"event" => "games/status", "payload" => %{game: "EVThree"}}},
                     50
    end

    test "does not support the games feature - ref", %{state: state} do
      frame = %{
        "event" => "games/status",
        "ref" => "ref"
      }

      assert {:ok, response, _state} = Router.receive(state, frame)

      assert response["ref"] == "ref"
      assert response["status"] == "failure"
    end

    test "request game status updates for a single game", %{state: state} do
      state = %{state | supports: ["channels", "games"]}

      frame = %{
        "event" => "games/status",
        "ref" => UUID.uuid4(),
        "payload" => %{
          "game" => "EVTwo"
        }
      }

      assert {:ok, :skip, _state} = Router.receive(state, frame)

      refute_receive {:broadcast, %{"event" => "games/status", "payload" => %{game: "EVOne"}}}, 50
      assert_receive {:broadcast, %{"event" => "games/status", "payload" => %{game: "EVTwo"}}}, 50
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
