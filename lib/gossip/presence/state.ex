defmodule Gossip.Presence.State do
  @moduledoc """
  Struct for game presence
  """

  defstruct [:type, :game, :players, :supports, :channels, :timestamp]
end
