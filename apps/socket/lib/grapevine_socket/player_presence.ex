defmodule GrapevineSocket.PlayerPresence do
  @moduledoc """
  Stub module for the socket node to update player presence on the main node
  """

  @doc """
  Follows the same cast as `Grapevine.PlayerPresence.update_count/2`
  """
  def update_count(game_id, count) do
    case :pg2.get_members(Grapevine.PlayerPresence) do
      members when is_list(members) ->
        Enum.each(members, fn pid ->
          GenServer.cast(pid, {:update_count, game_id, count})
        end)

      {:error, {:no_such_group, Grapevine.PlayerPresence}} ->
        raise "Issue broadcasting to the player presence servers"
    end
  end
end
