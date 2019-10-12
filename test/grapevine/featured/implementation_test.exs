defmodule Grapevine.Featured.ImplementationTest do
  use Grapevine.DataCase

  alias Grapevine.Featured.Implementation
  alias GrapevineData.Games
  alias GrapevineData.Statistics

  describe "determining the amount of milliseconds to delay" do
    test "for the next cycle" do
      now =
        Timex.now()
        |> Timex.set(hour: 20, minute: 0, second: 0)
        |> DateTime.truncate(:second)

      delay = Implementation.calculate_next_cycle_delay(now)

      assert delay == 36_000_000
    end

    test "process is rebooted same day but before cycle runs" do
      now =
        Timex.now()
        |> Timex.set(hour: 4, minute: 0, second: 0)
        |> DateTime.truncate(:second)

      delay = Implementation.calculate_next_cycle_delay(now)

      assert delay == 3600 * 2 * 1000
    end
  end

  describe "selecting games to feature" do
    test "updates the sort order for all games" do
      user = create_user()
      game1 = create_game(user, %{name: "Game 1", short_name: "Game1"})
      game2 = create_game(user, %{name: "Game 2", short_name: "Game2"})
      game3 = create_game(user, %{name: "Game 3", short_name: "Game3"})

      Games.seen_on_telnet(game1)
      {:ok, _stats} = Statistics.record_mssp_players(game1, 2, Timex.now())
      Games.seen_on_socket(game2)
      Games.seen_on_telnet(game3)

      Implementation.select_featured()

      Enum.each([game1, game2, game3], fn game ->
        {:ok, game} = Games.get(game.id)
        assert game.featured_order
      end)
    end

    test "selects from all three" do
      user = create_user()
      game1 = create_game(user, %{name: "Game 1", short_name: "Game1"})
      game2 = create_game(user, %{name: "Game 2", short_name: "Game2"})
      game3 = create_game(user, %{name: "Game 3", short_name: "Game3"})

      Games.seen_on_telnet(game1)
      {:ok, _stats} = Statistics.record_mssp_players(game1, 2, Timex.now())
      Games.seen_on_telnet(game2)
      Games.seen_on_socket(game3)

      games = Implementation.featured_games()

      game_ids =
        games
        |> Enum.map(& &1.id)
        |> Enum.sort()

      assert game_ids == [game1.id, game2.id, game3.id]
    end

    test "top games based on player count" do
      user = create_user()
      game1 = create_game(user, %{name: "Game 1", short_name: "Game1"})
      game2 = create_game(user, %{name: "Game 2", short_name: "Game2"})
      _game3 = create_game(user, %{name: "Game 3", short_name: "Game3"})

      Games.seen_on_telnet(game1)
      {:ok, _stats} = Statistics.record_mssp_players(game1, 2, Timex.now())
      Games.seen_on_telnet(game2)
      {:ok, _stats} = Statistics.record_mssp_players(game2, 3, Timex.now())

      games = Implementation.top_games_player_count(select: 2)

      game_ids =
        games
        |> Enum.map(& &1.id)
        |> Enum.sort()

      assert game_ids == [game1.id, game2.id]
    end

    test "random games connected to the chat network" do
      user = create_user()
      game1 = create_game(user, %{name: "Game 1", short_name: "Game1"})
      game2 = create_game(user, %{name: "Game 2", short_name: "Game2"})
      _game3 = create_game(user, %{name: "Game 3", short_name: "Game3"})

      Games.seen_on_socket(game1)
      Games.seen_on_socket(game2)

      games = Implementation.random_games_using_grapevine(select: 2)

      game_ids =
        games
        |> Enum.map(& &1.id)
        |> Enum.sort()

      assert game_ids == [game1.id, game2.id]
    end

    test "random games not already picked using client or chat" do
      user = create_user()
      game1 = create_game(user, %{name: "Game 1", short_name: "Game1"})
      game2 = create_game(user, %{name: "Game 2", short_name: "Game2"})
      _game3 = create_game(user, %{name: "Game 3", short_name: "Game3"})

      Games.seen_on_socket(game1)
      Games.seen_on_socket(game2)

      games = Implementation.random_games_using_grapevine(select: 2, already_picked: [game1.id])

      game_ids =
        games
        |> Enum.map(& &1.id)
        |> Enum.sort()

      assert game_ids == [game2.id]
    end

    test "random selection of games that have not been picked" do
      user = create_user()
      game1 = create_game(user, %{name: "Game 1", short_name: "Game1"})
      game2 = create_game(user, %{name: "Game 2", short_name: "Game2"})
      game3 = create_game(user, %{name: "Game 3", short_name: "Game3"})

      Games.seen_on_telnet(game1)
      Games.seen_on_telnet(game2)
      Games.seen_on_telnet(game3)

      games = Implementation.random_games(select: 2, already_picked: [game1.id])

      game_ids =
        games
        |> Enum.map(& &1.id)
        |> Enum.sort()

      assert game_ids == [game2.id, game3.id]
    end
  end
end
