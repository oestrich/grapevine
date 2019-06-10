defmodule Socket.PresenceTest do
  use Grapevine.DataCase

  alias Socket.Presence

  describe "updating presence of a game" do
    test "on update the game is shown as online" do
      user = create_user()
      game = create_game(user, %{name: "MUD Game"})
      supports = ["channels"]
      players = ["player"]

      Presence.reset()

      :ok = Presence.update_game(presence_state(game, %{supports: supports, players: players}))

      assert [_ | [%{supports: ^supports, players: ^players}]] = Presence.online_games()
    end
  end
end
