defmodule Web.Socket.State do
  @moduledoc """
  Struct for socket state
  """

  @doc """
  - status: "active" or "inactive"
  - game: the connected game when active
  - hearbeat_count: the count of heartbeats with no response
  """
  defstruct [:status, :game, heartbeat_count: 0]
end
