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

  @doc """
  Check if the client is allowed to load

  If anonymous users are not allowed, a user must be present
  """
  def client_allowed?(game, assigns, user_key) do
    case game.allow_anonymous_client do
      true ->
        {:ok, :allowed}

      false ->
        case Map.has_key?(assigns, user_key) && !is_nil(Map.get(assigns, user_key)) do
          true ->
            {:ok, :allowed}

          false ->
            {:error, :not_signed_in}
        end
    end
  end
end
