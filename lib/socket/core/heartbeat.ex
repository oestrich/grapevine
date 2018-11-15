defmodule Socket.Core.Heartbeat do
  @moduledoc """
  Handle a heartbeat internally to Gossip
  """

  require Logger

  def handle(state = %{status: "inactive"}) do
    state = Map.put(state, :heartbeat_count, state.heartbeat_count + 1)

    case state.heartbeat_count > 3 do
      true ->
        Telemetry.execute([:gossip, :sockets, :heartbeat, :disconnect], 1, %{})
        {:disconnect, state}

      false ->
        {:ok, state}
    end
  end

  def handle(state) do
    case state do
      %{heartbeat_count: count} when count >= 3 ->
        Telemetry.execute([:gossip, :sockets, :heartbeat, :disconnect], 1, %{})

        {:disconnect, state}

      _ ->
        state = Map.put(state, :heartbeat_count, state.heartbeat_count + 1)
        {:ok, %{event: "heartbeat"}, state}
    end
  end
end
