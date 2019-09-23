defmodule Socket.Handler.Players do
  @moduledoc """
  Player status subscription feature module
  """

  use Socket.Web.Module

  alias Socket.Handler.Core
  alias Socket.Presence
  alias Socket.PubSub

  @doc """
  Maybe subcsribe to the players status channel, only if the socket supports it
  """
  def maybe_listen_to_players_channel(state) do
    case supports_players?(state) do
      true ->
        PubSub.subscribe("players:status")

      false ->
        :ok
    end
  end

  @doc """
  Check if the socket supports players
  """
  def supports_players?(state), do: "players" in state.supports

  @doc """
  Receive a new player sign in, broadcast it
  """
  def player_sign_in(_state, %{"payload" => %{"name" => ""}}) do
    {:error, "Name cannot be empty"}
  end

  def player_sign_in(state, %{"payload" => %{"name" => name}}) do
    :telemetry.execute([:grapevine, :events, :players, :sign_in], %{count: 1}, %{name: name})

    case name in state.players do
      true ->
        {:ok, state}

      false ->
        sign_player_in(state, name)
    end
  end

  def player_sign_in(_state, _event), do: :error

  defp sign_player_in(state, name) do
    maybe_broadcast_signin(state, name)

    players = Enum.uniq([name | state.players])
    state = %{state | players: players}
    Presence.update_game(state)

    {:ok, state}
  end

  defp maybe_broadcast_signin(state, name) do
    case display?(state.game) do
      true ->
        token()
        |> assign(:game, state.game)
        |> assign(:name, name)
        |> payload("sign-in")
        |> broadcast("players:status", "players/sign-in")

      false ->
        :ok
    end
  end

  @doc """
  Receive a new player sign out, broadcast it
  """
  def player_sign_out(state, %{"payload" => %{"name" => name}}) do
    :telemetry.execute([:grapevine, :events, :players, :sign_out], %{count: 1}, %{name: name})

    case name in state.players do
      true ->
        sign_player_out(state, name)

      false ->
        {:ok, :skip, state}
    end
  end

  def player_sign_out(_state, _event), do: :error

  defp sign_player_out(state, name) do
    maybe_broadcast_signout(state, name)

    players = List.delete(state.players, name)
    state = %{state | players: players}
    Presence.update_game(state)

    {:ok, state}
  end

  defp maybe_broadcast_signout(state, name) do
    case display?(state.game) do
      true ->
        token()
        |> assign(:game, state.game)
        |> assign(:name, name)
        |> payload("sign-out")
        |> broadcast("players:status", "players/sign-out")

      false ->
        :ok
    end
  end

  @doc """
  Request player status, of connected games
  """
  def request_status(state, %{"ref" => ref, "payload" => %{"game" => game_name}})
      when ref != nil do
    :telemetry.execute([:grapevine, :events, :players, :status], %{count: 1}, %{game: game_name})

    Presence.online_games()
    |> Enum.find(&find_game(&1, game_name))
    |> maybe_relay_state(ref)

    {:ok, :skip, state}
  end

  def request_status(state, %{"ref" => ref}) when ref != nil do
    :telemetry.execute([:grapevine, :events, :players, :status], %{count: 1}, %{all: true})

    Presence.online_games()
    |> Enum.filter(&display?(&1.game))
    |> Core.remove_self_from_game_list(state)
    |> Enum.each(&relay_state(&1, ref))

    {:ok, :skip, state}
  end

  def request_status(_state, _), do: :error

  defp find_game(state, name) do
    state.game.short_name == name
  end

  defp display?(game) do
    game.display && game.display_players
  end

  defp maybe_relay_state(nil, ref) do
    token()
    |> assign(:ref, ref)
    |> event("unknown")
    |> relay()
  end

  defp maybe_relay_state(game, ref), do: relay_state(game, ref)

  defp relay_state(state, ref) do
    token()
    |> assign(:ref, ref)
    |> assign(:game, state.game)
    |> assign(:players, state.players)
    |> event("status")
    |> relay()
  end

  defmodule View do
    @moduledoc """
    "View" module for players

    Helps contain what each event looks look as a response
    """

    def payload("sign-in", %{game: game, name: name}) do
      %{
        "game" => game.short_name,
        "game_id" => game.client_id,
        "name" => name
      }
    end

    def payload("sign-out", %{game: game, name: name}) do
      %{
        "game" => game.short_name,
        "game_id" => game.client_id,
        "name" => name
      }
    end

    def event("status", %{ref: ref, game: game, players: players}) do
      %{
        "event" => "players/status",
        "ref" => ref,
        "payload" => %{
          "game" => game.short_name,
          "players" => players
        }
      }
    end

    def event("unknown", %{ref: ref}) do
      %{
        "event" => "players/status",
        "ref" => ref,
        "status" => "failure",
        "error" => "unknown game"
      }
    end
  end
end
