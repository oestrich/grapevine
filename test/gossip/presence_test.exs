defmodule Gossip.PresenceTest do
  use Gossip.DataCase

  alias Gossip.Presence

  describe "updating presence of a game" do
    setup do
      user = create_user()
      game = create_game(user, %{name: "MUD Game"})
      supports = ["channels"]
      players = ["player"]

      Presence.reset()

      %{game: game, supports: supports, players: players}
    end

    test "on update the game is shown as online", %{game: game, supports: supports, players: players} do
      :ok = Presence.update_game(game, supports, players)

      assert [%{supports: ^supports, players: ^players}] = Presence.online_games()
    end
  end
end
