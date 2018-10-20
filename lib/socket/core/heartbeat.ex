defmodule Socket.Core.Heartbeat do
  @moduledoc """
  Handle a heartbeat internally to Gossip
  """

  require Logger

  alias Metrics.SocketInstrumenter

  def handle(state = %{status: "inactive"}) do
    state = Map.put(state, :heartbeat_count, state.heartbeat_count + 1)

    Logger.debug("Inactive heartbeat", type: :heartbeat)

    case state.heartbeat_count > 3 do
      true ->
        SocketInstrumenter.heartbeat_disconnect()
        {:disconnect, state}

      false ->
        {:ok, state}
    end
  end

  def handle(state) do
    SocketInstrumenter.heartbeat()

    case state do
      %{heartbeat_count: count} when count >= 3 ->
        SocketInstrumenter.heartbeat_disconnect()

        {:disconnect, state}

      _ ->
        state = Map.put(state, :heartbeat_count, state.heartbeat_count + 1)
        {:ok, %{event: "heartbeat"}, state}
    end
  end
end

