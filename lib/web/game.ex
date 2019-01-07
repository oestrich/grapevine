defmodule Web.Game do
  @moduledoc """
  Helpers for games in the web view
  """

  @doc """
  Chose a random game that is online and has a home page
  """
  @spec highlighted_game([Game.t()]) :: Game.t()
  def highlighted_game(games) do
    games
    |> Enum.map(& &1.game)
    |> Enum.filter(& &1.display)
    |> Enum.filter(&(&1.homepage_url != nil))
    |> Enum.shuffle()
    |> List.first()
  end
end
