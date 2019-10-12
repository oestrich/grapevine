defmodule Grapevine.Statistics do
  @moduledoc """
  Statistics context
  """

  import Ecto.Query

  alias GrapevineData.Repo
  alias GrapevineData.Statistics.Session

  @doc """
  Find a list of games with active web clients

  Returns three games with the most recently closed web client. If one
  is open, it is returned on the top.
  """
  def active_games() do
    time_limit = Timex.now() |> Timex.shift(weeks: -1)

    Session
    |> distinct([s], s.game_id)
    |> where([s], s.started_at > ^time_limit)
    |> order_by([s], desc: s.closed_at)
    |> subquery()
    |> order_by([s], desc_nulls_first: s.closed_at)
    |> limit(3)
    |> Repo.all()
    |> Enum.map(fn session ->
      {:ok, game} = GrapevineData.Games.get(session.game_id)
      game
    end)
  end
end
