defmodule Web.Socket.Games do
  @moduledoc """
  Games support flag
  """

  alias Gossip.Presence
  alias Web.GameView
  alias Web.Socket.Implementation

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
  """
  def request_status(state, %{"ref" => ref, "payload" => %{"game" => game_name}}) when ref != nil do
    case supports_games?(state) do
      true ->
        Presence.online_games()
        |> Enum.find(&find_game(&1, game_name))
        |> maybe_broadcast_game(ref)

        {:ok, state}

      false ->
        {:error, :missing_support}
    end
  end

  def request_status(state, %{"ref" => ref}) when ref != nil do
    case supports_games?(state) do
      true ->
        Presence.online_games()
        |> Enum.filter(&(&1.game.display))
        |> Implementation.remove_self_from_game_list(state)
        |> Enum.each(&broadcast_state(&1, ref))

        {:ok, state}

      false ->
        {:error, :missing_support}
    end
  end

  def request_status(_state, _), do: :error

  defp find_game(state, name) do
    state.game.short_name == name
  end

  defp maybe_broadcast_game(nil, ref) do
    event = %{
      "event" => "games/status",
      "ref" => ref,
      "status" => "failure",
      "error" => "unknown game"
    }

    send(self(), {:broadcast, event})
  end

  defp maybe_broadcast_game(game, ref), do: broadcast_state(game, ref)

  defp broadcast_state(presence, ref) do
    game_payload = GameView.render("status.json", %{game: presence.game})

    payload = Map.merge(game_payload, %{
      supports: presence.supports,
      player_online_count: length(presence.players),
    })

    event = %{
      "event" => "games/status",
      "ref" => ref,
      "status" => "success",
      "payload" => payload
    }

    send(self(), {:broadcast, event})
  end
end
