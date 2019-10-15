defmodule Socket.Web.State do
  @moduledoc """
  Struct for socket state
  """

  @doc """
  - status: "active" or "inactive"
  - game: the connected game when active
  - supports: list of features the socket supporst
  - channels: list of channels the socket is subscribed to
  - players: list of connected players
  - debug: if debug mode is on or off
  - hearbeat_count: the count of heartbeats with no response
  - rate_limits: map of rate limit states
  """
  defstruct [
    :status,
    :game,
    :supports,
    :channels,
    :players,
    debug: false,
    heartbeat_count: 0,
    rate_limits: %{}
  ]
end
