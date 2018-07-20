defmodule Gossip.Presence.State do
  @moduledoc """
  Struct for game presence
  """

  defstruct [:game, :supports, :players, :timestamp]
end
