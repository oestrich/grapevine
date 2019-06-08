defmodule Socket.Web.Router do
  @moduledoc """
  WebSocket Implementation

  Contains server code for the websocket handler
  """

  require Logger

  alias Socket.Core

  import Socket.Web.RouterMacro

  receives(Socket) do
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

    module(Achievements, "achievements") do
      event("achievements/sync", :sync)
      event("achievements/create", :create)
      event("achievements/update", :update)
      event("achievements/delete", :delete)
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
    :telemetry.execute([:grapevine, :sockets, :events, :unknown], %{count: 1}, %{state: state, frame: frame})
    {:ok, %{status: "failure", error: "unknown"}, state}
  end
end
