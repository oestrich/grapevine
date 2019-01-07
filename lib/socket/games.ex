defmodule Socket.Games do
  @moduledoc """
  Games support flag
  """

  use Web.Socket.Module

  alias Gossip.Games
  alias Gossip.Presence
  alias Socket.Core

  @doc """
  Check if the socket supports games
  """
  def supports_games?(state), do: "games" in state.supports

  @doc """
  Maybe subcsribe to the games status channel, only if the socket supports it
  """
  def maybe_listen_to_games_channel(state) do
    case supports_games?(state) do
      true ->
        Web.Endpoint.subscribe("games:status")

      false ->
        :ok
    end
  end

  @doc """
  Request game status, of connected games

  Can request a single game
  """
  def request_status(state, %{"ref" => ref, "payload" => %{"game" => game_name}})
      when ref != nil do
    :telemetry.execute([:gossip, :events, :games, :status], 1, %{game: game_name})

    Presence.online_games()
    |> Enum.find(&find_game(&1, game_name))
    |> maybe_relay_game(ref)

    {:ok, :skip, state}
  end

  def request_status(state, %{"ref" => ref}) when ref != nil do
    :telemetry.execute([:gossip, :events, :games, :status], 1, %{all: true})

    Presence.online_games()
    |> Enum.filter(& &1.game.display)
    |> Core.remove_self_from_game_list(state)
    |> Enum.each(&relay_state(&1, ref))

    {:ok, :skip, state}
  end

  def request_status(_state, _), do: :error

  defp find_game(state, name) do
    state.game.short_name == name
  end

  defp maybe_relay_game(nil, ref) do
    token()
    |> assign(:ref, ref)
    |> event("unknown")
    |> relay()
  end

  defp maybe_relay_game(game, ref), do: relay_state(game, ref)

  defp relay_state(presence, ref) do
    token()
    |> assign(:ref, ref)
    |> assign(:presence, presence)
    |> event("game")
    |> relay()
  end

  @doc """
  Broadcast a game connecting for the first time to Gossip

  See `Gossip.Presence.Notices` as well
  """
  def broadcast_connect_event(:game, game_id) do
    with {:ok, game} <- Games.get(game_id) do
      token()
      |> assign(:game, game)
      |> payload("games/connect")
      |> broadcast("games:status", "games/connect")
    end
  end

  def broadcast_connect_event(:application, _app_id), do: :ok

  @doc """
  Broadcast a game disconnecting completely from Gossip

  See `Gossip.Presence.Notices` as well
  """
  def broadcast_disconnect_event(:game, game_id) do
    with {:ok, game} <- Games.get(game_id) do
      token()
      |> assign(:game, game)
      |> payload("games/disconnect")
      |> broadcast("games:status", "games/disconnect")
    end
  end

  def broadcast_disconnect_event(:application, _app_id), do: :ok

  defmodule View do
    @moduledoc """
    "View" module for games

    Helps contain what each event looks look as a response
    """

    alias Web.GameView

    def event("unknown", %{ref: ref}) do
      %{
        "event" => "games/status",
        "ref" => ref,
        "status" => "failure",
        "error" => "unknown game"
      }
    end

    def event("game", %{ref: ref, presence: presence}) do
      game_payload = GameView.render("status.json", %{game: presence.game})

      payload =
        Map.merge(game_payload, %{
          supports: presence.supports,
          player_online_count: length(presence.players)
        })

      %{
        "event" => "games/status",
        "ref" => ref,
        "status" => "success",
        "payload" => payload
      }
    end

    def payload("games/connect", %{game: game}) do
      %{
        "game" => game.short_name,
        "game_id" => game.client_id
      }
    end

    def payload("games/disconnect", %{game: game}) do
      %{"game" => game.short_name}
    end
  end
end
