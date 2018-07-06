defmodule Web.Socket.Implementation do
  @moduledoc """
  WebSocket Implementation

  Contains server code for the websocket handler
  """

  require Logger

  alias Gossip.Channels
  alias Gossip.Games
  alias Gossip.Presence

  @valid_supports ["channels"]

  def heartbeat(state) do
    case state do
      %{heartbeat_count: count} when count >= 3 ->
        {:disconnect, state}

      _ ->
        state = Map.put(state, :heartbeat_count, state.heartbeat_count + 1)
        {:ok, %{event: "heartbeat"}, state}
    end
  end

  def receive(state = %{status: "inactive"}, %{"event" => "authenticate", "payload" => payload}) do
    with {:ok, game} <- validate_socket(payload),
         {:ok, supports} <- validate_supports(payload) do
      finalize_auth(state, game, payload, supports)
    else
      {:error, :invalid} ->
        {:disconnect, %{event: "authenticate", status: "failure", error: "invalid credentials"}, state}

      {:error, :missing_supports} ->
        {:disconnect, %{event: "authenticate", status: "failure", error: "missing supports"}, state}

      {:error, :must_support_channels} ->
        {:disconnect, %{event: "authenticate", status: "failure", error: "must support channels"}, state}

      {:error, :unknown_supports} ->
        {:disconnect, %{event: "authenticate", status: "failure", error: "includes unknown supports"}, state}
    end
  end

  def receive(state = %{status: "active"}, %{"event" => "messages/new", "payload" => payload}) do
    case Map.fetch(payload, "channel") do
      {:ok, channel} ->
        payload =
          payload
          |> Map.put("id", UUID.uuid4())
          |> Map.put("game", state.game.short_name)
          |> Map.put("game_id", state.game.client_id)
          |> Map.take(["id", "channel", "game", "game_id", "name", "message"])

          Web.Endpoint.broadcast("channels:#{channel}", "messages/broadcast", payload)
          {:ok, state}
    end
  end

  def receive(state = %{status: "active"}, event = %{"event" => "heartbeat"}) do
    Logger.debug(fn -> "HEARTBEAT: #{inspect(event["payload"])}" end)
      payload = Map.get(event, "payload", %{})
      Presence.update_game(state.game, Map.get(payload, "players", []))
      state = Map.put(state, :heartbeat_count, 0)
      {:ok, state}
  end

  def receive(state, _frame) do
    {:ok, %{status: "unknown"}, state}
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
    case Enum.all?(supports, &Enum.member?(@valid_supports, &1)) do
      true ->
        {:ok, supports}

      false ->
        {:error, :unknown_supports}
    end
  end

  defp finalize_auth(state, game, payload, supports) do
    state =
      state
      |> Map.put(:status, "active")
      |> Map.put(:game, game)
      |> Map.put(:supports, supports)

    listen_to_channels(payload)

    Logger.info("Authenticated #{game.name}")
    Presence.update_game(state.game, Map.get(payload, "players", []))

    {:ok, %{event: "authenticate", status: "success"}, state}
  end

  defp listen_to_channels(payload) do
    payload
    |> Map.get("channels", [])
    |> Enum.map(&Channels.ensure_channel/1)
    |> Enum.each(fn channel ->
      Web.Endpoint.subscribe("channels:#{channel}")
    end)
  end
end
