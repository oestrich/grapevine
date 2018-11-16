defmodule Gossip.StatisticsTest do
  use Gossip.DataCase

  alias Gossip.Statistics

  describe "record player count for a game" do
    test "successful" do
      game = create_game(create_user())

      {:ok, stats} = Statistics.record_players(game, 10, Timex.now())

      assert stats.player_count == 10
    end
  end

  describe "recent stats" do
    test "fetch the last week of stats" do
      game = create_game(create_user())

      now = Timex.now()
      Enum.each(1..15, fn i ->
        now = Timex.shift(now, minutes: -15 * i)
        {:ok, _stats} = Statistics.record_players(game, i, now)
      end)

      stats = Statistics.last_week(game)

      stats =
        stats
        |> Enum.take(-15)
        |> Enum.map(&elem(&1, 1))
        |> Enum.take(14)

      assert Enum.all?(stats, &(&1 > 0))
    end
  end
end
