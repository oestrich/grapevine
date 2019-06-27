defmodule Socket.Handler.Core.Authenticate do
  @moduledoc """
  Handles the "authenticate" event
  """

  require Logger

  alias GrapevineData.Channels
  alias GrapevineData.Games
  alias Socket.Handler.Core
  alias Socket.Handler.Games, as: SocketGames
  alias Socket.Handler.Players
  alias Socket.Handler.Tells
  alias Socket.Presence

  @disable_debug_seconds 300

  def process(state, payload) do
    :telemetry.execute([:grapevine, :sockets, :connect], %{count: 1}, %{})

    with {:ok, game} <- validate_socket(payload),
         {:ok, supports} <- validate_supports(game, payload) do
      finalize_auth(state, game, payload, supports)
    else
      {:error, :invalid} ->
        :telemetry.execute([:grapevine, :sockets, :connect, :failure], %{count: 1}, %{
          reason: "invalid authenticat event"
        })

        {:disconnect, %{event: "authenticate", status: "failure", error: "invalid credentials"},
         state}

      {:error, :missing_supports} ->
        :telemetry.execute([:grapevine, :sockets, :connect, :failure], %{count: 1}, %{
          reason: "missing supports"
        })

        {:disconnect, %{event: "authenticate", status: "failure", error: "missing supports"},
         state}

      {:error, :must_support_channels} ->
        :telemetry.execute([:grapevine, :sockets, :connect, :failure], %{count: 1}, %{
          reason: "must support channels"
        })

        {:disconnect, %{event: "authenticate", status: "failure", error: "must support channels"},
         state}

      {:error, :unknown_supports} ->
        :telemetry.execute([:grapevine, :sockets, :connect, :failure], %{count: 1}, %{
          reason: "unknown set of supports"
        })

        {:disconnect,
         %{event: "authenticate", status: "failure", error: "includes unknown supports"}, state}
    end
  end

  def finalize_auth(state, game, payload, supports) do
    channels = Map.get(payload, "channels", [])
    players = Map.get(payload, "players", [])
    debug = Map.get(payload, "debug", false)

    state =
      state
      |> Map.put(:status, "active")
      |> Map.put(:game, game)
      |> Map.put(:supports, supports)
      |> Map.put(:channels, channels)
      |> Map.put(:players, players)
      |> Map.put(:debug, debug)

    listen_to_channels(channels)
    Players.maybe_listen_to_players_channel(state)
    SocketGames.maybe_listen_to_games_channel(state)
    Tells.maybe_subscribe(state)

    maybe_schedule_disable_debug(state)

    :telemetry.execute([:grapevine, :sockets, :connect, :success], %{count: 1}, %{
      game: game.name,
      channels: channels,
      supports: supports
    })

    Presence.track(state)

    response = %{
      event: "authenticate",
      status: "success",
      payload: %{
        unicode: "✔️",
        version: Grapevine.version()
      }
    }

    send(self(), :heartbeat)

    {:ok, response, state}
  end

  defp maybe_schedule_disable_debug(state) do
    case state.debug do
      true ->
        Process.send_after(self(), {:disable_debug}, :timer.seconds(@disable_debug_seconds))

      false ->
        :ok
    end
  end

  defp validate_socket(payload) do
    client_id = Map.get(payload, "client_id")
    client_secret = Map.get(payload, "client_secret")

    Games.validate_socket(client_id, client_secret, payload)
  end

  defp validate_supports(game, payload) do
    with {:ok, supports} <- get_supports(payload),
         {:ok, supports} <- check_supports_for_channels(supports),
         {:ok, supports} <- check_unknown_supports(supports),
         {:ok, supports} <- check_for_players_and_tells(game, supports) do
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
    case Enum.all?(supports, &Core.valid_support?/1) do
      true ->
        {:ok, supports}

      false ->
        {:error, :unknown_supports}
    end
  end

  defp check_for_players_and_tells(game, supports) do
    case game.display_players do
      true ->
        {:ok, supports}

      false ->
        supports = List.delete(supports, "tells")
        {:ok, supports}
    end
  end

  defp listen_to_channels(channels) do
    channels
    |> Enum.map(&Channels.ensure_channel/1)
    |> Enum.each(&Core.subscribe_channel/1)
  end
end
