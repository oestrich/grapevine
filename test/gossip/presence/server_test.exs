defmodule Grapevine.Presence.ServerTest do
  use Grapevine.DataCase

  alias Grapevine.Presence
  alias Grapevine.Presence.Server
  alias Grapevine.Statistics

  describe "recording online game stats" do
    test "saves state" do
      game = create_game(create_user())

      Presence.update_game(presence_state(game, %{supports: ["channels"], players: ["Player"]}))

      {:ok, %{}} = Server.record_statistics(%{})

      assert length(Statistics.all_player_counts(game)) == 1
    end
  end
end
