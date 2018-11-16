defmodule Gossip.Presence.ServerTest do
  use Gossip.DataCase

  alias Gossip.Presence
  alias Gossip.Presence.Server
  alias Gossip.Statistics

  describe "recording online game stats" do
    test "saves state" do
      game = create_game(create_user())

      Presence.update_game(game, ["channels"], ["Player"])

      {:ok, %{}} = Server.record_statistics(%{})

      assert length(Statistics.all_player_counts(game)) == 1
    end
  end
end
