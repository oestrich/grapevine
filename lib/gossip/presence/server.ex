defmodule Gossip.Presence.Server do
  @moduledoc """
  Implementation of the Presence server
  """

  import Gossip.Presence, only: [ets_key: 0]

  def update_game(state, game, players) do
    :ets.insert(ets_key(), {game.id, players, Timex.now()})
    {:ok, state}
  end
end
