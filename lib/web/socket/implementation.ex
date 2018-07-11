defmodule Web.Socket.Implementation do
  @moduledoc """
  WebSocket Implementation

  Contains server code for the websocket handler
  """

  require Logger

  alias Gossip.Channels
  alias Gossip.Games
  alias Gossip.Presence
  alias Metrics.ChannelsInstrumenter
  alias Metrics.SocketInstrumenter

  @valid_supports ["channels", "players"]

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

  def receive(state = %{status: "inactive"}, %{"event" => "authenticate", "payload" => payload}) do
    SocketInstrumenter.connect()

    with {:ok, game} <- validate_socket(payload),
         {:ok, supports} <- validate_supports(payload) do
      finalize_auth(state, game, payload, supports)
    else
      {:error, :invalid} ->
        SocketInstrumenter.connect_failure()

        {:disconnect, %{event: "authenticate", status: "failure", error: "invalid credentials"}, state}

      {:error, :missing_supports} ->
        SocketInstrumenter.connect_failure()

        {:disconnect, %{event: "authenticate", status: "failure", error: "missing supports"}, state}

      {:error, :must_support_channels} ->
        SocketInstrumenter.connect_failure()

        {:disconnect, %{event: "authenticate", status: "failure", error: "must support channels"}, state}

      {:error, :unknown_supports} ->
        SocketInstrumenter.connect_failure()

        {:disconnect, %{event: "authenticate", status: "failure", error: "includes unknown supports"}, state}
    end
  end

  def receive(state = %{status: "active"}, event = %{"event" => "channels/subscribe", "payload" => payload}) do
    with {:ok, channel} <- Map.fetch(payload, "channel"),
         {:ok, channel} <- Channels.ensure_channel(channel) do
      state = Map.put(state, :channels, [channel | state.channels])

      ChannelsInstrumenter.subscribe()
      Web.Endpoint.subscribe("channels:#{channel}")

      {:ok, maybe_respond(event), state}
    else
      {:error, name} ->
        message = %{
          event: "channels/subscribe",
          status: "failure",
          error: ~s(Could not subscribe to '#{name}'),
        }

        {:ok, maybe_ref(message, event), state}

      _ ->
        {:ok, maybe_respond(event), state}
    end
  end

  def receive(state = %{status: "active"}, event = %{"event" => "channels/unsubscribe", "payload" => payload}) do
    with {:ok, channel} <- Map.fetch(payload, "channel") do
      channels = List.delete(state.channels, channel)
      state = Map.put(state, :channels, channels)

      ChannelsInstrumenter.unsubscribe()
      Web.Endpoint.unsubscribe("channels:#{channel}")

      {:ok, maybe_respond(event), state}
    else
      _ ->
        {:ok, maybe_respond(event), state}
    end
  end

  def receive(state = %{status: "active"}, event = %{"event" => "messages/new", "payload" => payload}) do
    with {:ok, channel} <- Map.fetch(payload, "channel"),
         {:ok, channel} <- check_channel_subscribed_to(state, channel)do
      payload =
        payload
        |> Map.put("game", state.game.short_name)
        |> Map.put("game_id", state.game.client_id)
        |> Map.take(["id", "channel", "game", "game_id", "name", "message"])

      ChannelsInstrumenter.messages_new()
      Web.Endpoint.broadcast("channels:#{channel}", "messages/broadcast", payload)

      {:ok, maybe_respond(event), state}
    else
      _ ->
        {:ok, maybe_respond(event), state}
    end
  end

  def receive(state = %{status: "active"}, event = %{"event" => "heartbeat"}) do
    Logger.debug(fn ->
      "HEARTBEAT: #{inspect(event["payload"])}"
    end)

    SocketInstrumenter.heartbeat()

    payload = Map.get(event, "payload", %{})
    Presence.update_game(state.game, state.supports, Map.get(payload, "players", []))
    state = Map.put(state, :heartbeat_count, 0)

    {:ok, state}
  end

  def receive(state, _frame) do
    SocketInstrumenter.unknown_event()
    {:ok, %{status: "unknown"}, state}
  end

  def valid_support?(support) do
    Enum.member?(@valid_supports, support)
  end

  defp validate_socket(payload) do
    Games.validate_socket(Map.get(payload, "client_id"), Map.get(payload, "client_secret"), payload)
  end

  defp validate_supports(payload) do
    with {:ok, supports} <- get_supports(payload),
         {:ok, supports} <- check_supports_for_channels(supports),
         {:ok, supports} <- check_unknown_supports(supports) do
      {:ok, supports}
    end
  end

  defp get_supports(payload) do
    case Map.get(payload, "supports", :error) do
      :error ->
        {:error, :missing_supports}

      [] ->
        {:error, :missing_supports}

      supports ->
        {:ok, supports}
    end
  end

  defp check_supports_for_channels(supports) do
    case "channels" in supports do
      true ->
        {:ok, supports}

      false ->
        {:error, :must_support_channels}
    end
  end

  defp check_unknown_supports(supports) do
    case Enum.all?(supports, &valid_support?/1) do
      true ->
        {:ok, supports}

      false ->
        {:error, :unknown_supports}
    end
  end

  defp finalize_auth(state, game, payload, supports) do
    channels = Map.get(payload, "channels", [])
    players = Map.get(payload, "players", [])

    state =
      state
      |> Map.put(:status, "active")
      |> Map.put(:game, game)
      |> Map.put(:supports, supports)
      |> Map.put(:channels, channels)

    listen_to_channels(channels)

    SocketInstrumenter.connect_success()
    Logger.info("Authenticated #{game.name} - subscribed to #{inspect(channels)}")
    Presence.update_game(state.game, state.supports, players)

    {:ok, %{event: "authenticate", status: "success"}, state}
  end

  defp listen_to_channels(channels) do
    channels
    |> Enum.map(&Channels.ensure_channel/1)
    |> Enum.each(&subscribe_channel/1)
  end

  defp subscribe_channel({:error, name}) do
    Logger.info("Trying to subscribe to a bad channel")

    event = %{
      event: "channels/subscribe",
      status: "failure",
      error: ~s(Could not subscribe to '#{name}'),
    }

    send(self(), {:broadcast, event})
  end

  defp subscribe_channel({:ok, channel}) do
    ChannelsInstrumenter.subscribe()
    Web.Endpoint.subscribe("channels:#{channel}")
  end

  defp check_channel_subscribed_to(state, channel) do
    case channel in state.channels do
      true ->
        {:ok, channel}

      false ->
        {:error, :not_subscribed}
    end
  end

  defp maybe_ref(message, event) do
    case Map.has_key?(event, "ref") do
      true ->
        Map.put(message, :ref, event["ref"])

      false ->
        message
    end
  end

  defp maybe_respond(event) do
    case Map.has_key?(event, "ref") do
      true ->
        Map.take(event, ["event", "ref"])

      false ->
        :skip
    end
  end
end
