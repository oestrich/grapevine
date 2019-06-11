defmodule Socket.Presence.State do
  @moduledoc """
  Struct for game presence
  """

  defstruct [:game, :players, :supports, :channels, :timestamp]
end
