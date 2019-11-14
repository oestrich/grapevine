defmodule GrapevineSocket.Presence.ServerTest do
  use GrapevineSocket.DataCase

  alias GrapevineSocket.Presence
  alias GrapevineSocket.Presence.Server
  alias GrapevineData.Statistics

  @tag :presence
  describe "recording online game stats" do
    test "saves state" do
      game = create_game(create_user())

      Presence.update_game(presence_state(game, %{supports: ["channels"], players: ["Player"]}))

      {:ok, %{}} = Server.record_statistics(%{})

      assert length(Statistics.all_player_counts(game)) == 1
    end
  end
end
