defmodule Web.Socket.Router do
  @moduledoc """
  WebSocket Implementation

  Contains server code for the websocket handler
  """

  require Logger

  alias Metrics.SocketInstrumenter
  alias Web.Socket.Backbone
  alias Web.Socket.Core

  def backbone_event(state, message) do
    Backbone.event(state, message)
  end

  def heartbeat(state = %{status: "inactive"}) do
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

  def heartbeat(state) do
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

  import Web.Socket.RouterMacro

  receives(Web.Socket) do
    module(Core, "channels") do
      event("heartbeat", :heartbeat)

      event("channels/subscribe", :channel_subscribe)
      event("channels/unsubscribe", :channel_unsubscribe)
      event("channels/send", :channel_send)
    end

    module(Players, "players") do
      event("players/sign-in", :player_sign_in)
      event("players/sign-out", :player_sign_out)
      event("players/status", :request_status)
    end

    module(Tells, "tells") do
      event("tells/send", :send)
    end

    module(Games, "games") do
      event("games/status", :request_status)
    end
  end

  def receive(state = %{status: "inactive"}, event = %{"event" => "authenticate"}) do
    state
    |> Core.authenticate(event)
    |> Response.wrap(event, "channels")
    |> Response.respond_to(state)
  end

  def receive(state = %{status: "inactive"}, frame) do
    Logger.warn("Getting an unknown frame unauthenticated - #{inspect(frame)}")
    {:ok, %{status: "failure", error: "unauthenticated"}, state}
  end

  def receive(state, frame) do
    Logger.warn("Getting an unknown frame - #{inspect(state)} - #{inspect(frame)}")
    SocketInstrumenter.unknown_event()
    {:ok, %{status: "failure", error: "unknown"}, state}
  end
end
