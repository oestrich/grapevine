defmodule Web.Socket.Tells do
  @moduledoc """
  Implementation for the `tells` flag
  """

  alias Gossip.Presence

  @doc """
  Subscribe to the game's tells internal channel if the socket supports it
  """
  def maybe_subscribe(state) do
    case supports_tells?(state) do
      true ->
        Web.Endpoint.subscribe("tells:#{state.game.short_name}")

      false ->
        :ok
    end
  end

  @doc """
  Send a tell to another game
  """
  def send(state, event) do
    with {:ok, :supports} <- check_supports(state),
         {:ok, payload} <- check_payload(event),
         {:ok, game, supports, players} <- check_game_online(payload),
         {:ok, :game, :supports} <- check_remote_game_supports(supports),
         :ok <- check_player_online(players, payload) do
      event = %{
        "game" => state.game.short_name,
        "from" => payload["from"],
        "player" => payload["player"],
        "sent_at" => payload["sent_at"],
        "message" => payload["message"]
      }

      Web.Endpoint.broadcast("tells:#{game.short_name}", "tells/receive", event)

      {:ok, state}
    else
      {:error, :missing_support} ->
        {:error, ~s(missing support for "tells")}

      {:error, :invalid_payload} ->
        {:error, ~s(invalid payload)}

      {:error, :game, :offline} ->
        {:error, ~s(game offline)}

      {:error, :game, :missing_support} ->
        {:error, ~s(not supported)}

      {:error, :player, :offline} ->
        {:error, ~s(player offline)}
    end
  end

  defp check_supports(state) do
    case supports_tells?(state) do
      true ->
        {:ok, :supports}

      false ->
        {:error, :missing_support}
    end
  end

  defp check_payload(event) do
    payload = Map.get(event, "payload", %{})

    case valid_payload?(payload) do
      true ->
        {:ok, payload}

      false ->
        {:error, :invalid_payload}
    end
  end

  defp check_game_online(payload) do
    game =
      Presence.online_games()
      |> Enum.find(&(elem(&1, 0).short_name == payload["game"]))

    case game do
      {game, supports, players, _timestamp} ->
        {:ok, game, supports, players}

      nil ->
        {:error, :game, :offline}
    end
  end

  defp check_remote_game_supports(supports) do
    case supports_tells?(%{supports: supports}) do
      true ->
        {:ok, :game, :supports}

      false ->
        {:error, :game, :missing_support}
    end
  end

  defp check_player_online(players, payload) do
    case payload["player"] in players do
      true ->
        :ok

      false ->
        {:error, :player, :offline}
    end
  end

  @doc """
  Check if the socket supports tells

      iex> Tells.supports_tells?(%{supports: ["tells"]})
      true

      iex> Tells.supports_tells?(%{supports: []})
      false
  """
  def supports_tells?(state), do: "tells" in state.supports

  @doc """
  Check if a send payload is valid
  """
  def valid_payload?(payload) do
    keys_present? = Enum.sort(Map.keys(payload)) == ["from", "game", "message", "player", "sent_at"]
    all_strings? = Enum.all?(Map.values(payload), &is_binary/1)

    keys_present? && all_strings? && valid_sent_at?(payload)
  end

  defp valid_sent_at?(payload) do
    case Timex.parse(payload["sent_at"], "{ISO:Extended}") do
      {:ok, _time} ->
        Regex.match?(~r/Z$/, payload["sent_at"])

      _ ->
        false
    end
  end
end
