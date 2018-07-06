defmodule Web.Socket.State do
  @moduledoc """
  Struct for socket state
  """

  @doc """
  - status: "active" or "inactive"
  - game: the connected game when active
  - supports: list of features the socket supporst
  - channels: list of channels the socket is subscribed to
  - hearbeat_count: the count of heartbeats with no response
  """
  defstruct [:status, :game, :supports, :channels, heartbeat_count: 0]
end
