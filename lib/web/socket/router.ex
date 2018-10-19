defmodule Web.Socket.Router do
  @moduledoc """
  WebSocket Implementation

  Contains server code for the websocket handler
  """

  require Logger

  alias Metrics.SocketInstrumenter
  alias Web.Socket.Backbone
  alias Web.Socket.Core
  alias Web.Socket.Games, as: SocketGames
  alias Web.Socket.Players
  alias Web.Socket.Response
  alias Web.Socket.Tells

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

  def receive(state = %{status: "inactive"}, event = %{"event" => "authenticate"}) do
    state
    |> Core.authenticate(event)
    |> Response.wrap(event, "channels")
    |> Response.respond_to(state)
  end

  def receive(state = %{status: "active"}, event = %{"event" => "channels/subscribe"}) do
    state
    |> Core.channel_subscribe(event)
    |> Response.wrap(event, "channels")
    |> Response.respond_to(state)
  end

  def receive(state = %{status: "active"}, event = %{"event" => "channels/unsubscribe"}) do
    state
    |> Core.channel_unsubscribe(event)
    |> Response.wrap(event, "channels")
    |> Response.respond_to(state)
  end

  def receive(state = %{status: "active"}, event = %{"event" => "channels/send"}) do
    state
    |> Core.channel_send(event)
    |> Response.wrap(event, "channels")
    |> Response.respond_to(state)
  end

  def receive(state = %{status: "active"}, event = %{"event" => "heartbeat"}) do
    state
    |> Core.heartbeat(event)
    |> Response.wrap(event, "channels")
    |> Response.respond_to(state)
  end

  def receive(state = %{status: "active"}, event = %{"event" => "players/sign-in"}) do
    state
    |> Players.player_sign_in(event)
    |> Response.wrap(event, "players")
    |> Response.respond_to(state)
  end

  def receive(state = %{status: "active"}, event = %{"event" => "players/sign-out"}) do
    state
    |> Players.player_sign_out(event)
    |> Response.wrap(event, "players")
    |> Response.respond_to(state)
  end

  def receive(state = %{status: "active"}, event = %{"event" => "players/status"}) do
    state
    |> Players.request_status(event)
    |> Response.wrap(event, "players")
    |> Response.respond_to(state)
  end

  def receive(state = %{status: "active"}, event = %{"event" => "tells/send"}) do
    state
    |> Tells.send(event)
    |> Response.wrap(event, "tells")
    |> Response.respond_to(state)
  end

  def receive(state = %{status: "active"}, event = %{"event" => "games/status"}) do
    state
    |> SocketGames.request_status(event)
    |> Response.wrap(event, "tells")
    |> Response.respond_to(state)
  end

  def receive(state = %{status: "inactive"}, frame) do
    Logger.warn("Getting an unknown frame unauthenticated - #{inspect(frame)}")
    {:ok, %{status: "failure", error: "unauthenticated"}, state}
  end

  def receive(state, frame) do
    Logger.warn("Getting an unknown frame - #{inspect(state)} - #{inspect(frame)}")
    SocketInstrumenter.unknown_event()
    {:ok, %{status: "unknown"}, state}
  end
end
