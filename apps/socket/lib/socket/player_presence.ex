defmodule Socket.PlayerPresence do
  @moduledoc """
  Stub module for the socket node to update player presence on the main node
  """

  @doc """
  Follows the same cast as `Grapevine.PlayerPresence.update_count/2`
  """
  def update_count(game_id, count) do
    GenServer.cast(Grapevine.PlayerPresence, {:update_count, game_id, count})
  end
end
