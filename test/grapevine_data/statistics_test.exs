defmodule GrapevineData.StatisticsTest do
  use Grapevine.DataCase

  alias GrapevineData.Statistics

  describe "record player count for a game" do
    test "from the socket" do
      game = create_game(create_user())

      {:ok, stats} = Statistics.record_socket_players(game, ["Guard", "Bandit"], Timex.now())

      assert stats.type == "socket"
      assert stats.player_count == 2
      assert stats.player_names == ["Guard", "Bandit"]
    end

    test "from mssp" do
      game = create_game(create_user())

      {:ok, stats} = Statistics.record_mssp_players(game, 2, Timex.now())

      assert stats.type == "mssp"
      assert stats.player_count == 2
      assert stats.player_names == []
    end
  end

  describe "recent stats" do
    test "fetch the last few days of stats" do
      game = create_game(create_user())

      now = Timex.now()

      Enum.each(1..15, fn i ->
        now = Timex.shift(now, minutes: -15 * i)
        {:ok, _stats} = Statistics.record_socket_players(game, ["Guard", "Bandit"], now)
      end)

      stats = Statistics.last_few_days(game)

      stats =
        stats
        |> Enum.take(-4)
        |> Enum.map(&elem(&1, 1))
        |> Enum.take(3)

      assert Enum.all?(stats, &(&1 > 0))
    end
  end

  describe "recording web client session data" do
    test "starting a new client" do
      game = create_game(create_user())

      {:ok, session} = Statistics.record_web_client_started(game, UUID.uuid4())

      assert session.game_id == game.id
      assert session.started_at
    end

    test "closing a client" do
      game = create_game(create_user())

      sid = UUID.uuid4()

      {:ok, _session} = Statistics.record_web_client_started(game, sid)

      {:ok, session} = Statistics.record_web_client_closed(sid)

      assert session.closed_at
    end
  end
end
