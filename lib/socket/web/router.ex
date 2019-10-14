defmodule Socket.Web.Router do
  @moduledoc """
  WebSocket Implementation

  Contains server code for the websocket handler
  """

  require Logger

  alias Socket.Handler.Core
  alias Socket.RateLimit.Limiter, as: RateLimiter

  import Socket.Web.RouterMacro

  receives(Socket.Handler) do
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
    :telemetry.execute([:grapevine, :sockets, :events, :unknown], %{count: 1}, %{
      state: state,
      frame: frame
    })

    {:ok, %{status: "failure", error: "unknown"}, state}
  end

  @doc """
  Process incoming text through a global rate limit
  """
  def process(state, frame) do
    with {:ok, state} <- RateLimiter.check_rate_limit(state, "global") do
      __MODULE__.receive(state, frame)
    else
      {:disconnect, :limit_exceeded, rate_limit} ->
        :telemetry.execute([:grapevine, :events, :rate_limited], rate_limit)
        {:disconnect, %{status: "failure", error: "rate limit exceeded, goodbye"}, state}

      {:error, :limit_exceeded, rate_limit} ->
        state = RateLimiter.update_rate_limit(state, "global", rate_limit)
        :telemetry.execute([:grapevine, :events, :rate_limited], rate_limit)
        {:ok, %{status: "failure", error: "rate limit exceeded"}, state}
    end
  end
end
