defmodule Socket.Handler.Core.Heartbeat do
  @moduledoc """
  Handle a heartbeat internally to Grapevine
  """

  require Logger

  def handle(state = %{status: "inactive"}) do
    state = Map.put(state, :heartbeat_count, state.heartbeat_count + 1)

    case state.heartbeat_count > 3 do
      true ->
        :telemetry.execute([:grapevine, :sockets, :heartbeat, :disconnect], %{count: 1}, %{})
        {:disconnect, state}

      false ->
        {:ok, state}
    end
  end

  def handle(state) do
    case state do
      %{heartbeat_count: count} when count >= 3 ->
        :telemetry.execute([:grapevine, :sockets, :heartbeat, :disconnect], %{count: 1}, %{})

        {:disconnect, state}

      _ ->
        state = Map.put(state, :heartbeat_count, state.heartbeat_count + 1)
        {:ok, %{event: "heartbeat"}, state}
    end
  end
end
