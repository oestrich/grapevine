defmodule Gossip.Presence.Server do
  @moduledoc """
  Implementation of the Presence server
  """

  import Gossip.Presence, only: [ets_key: 0]

  alias Gossip.Applications.Application
  alias Gossip.Games.Game

  def update_game(state, game, supports, players) do
    :ets.insert(ets_key(), {ets_key(game), %{supports: supports, players: players, timestamp: Timex.now()}})
    {:ok, state}
  end

  defp ets_key(game = %Game{}) do
    "game:#{game.id}"
  end

  defp ets_key(application = %Application{}) do
    "application:#{application.id}"
  end
end
