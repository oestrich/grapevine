defmodule Web.Socket.Tells do
  @moduledoc """
  Implementation for the `tells` flag
  """

  use Web.Socket.Module

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
    with {:ok, payload} <- check_payload(event),
         {:ok, %{game: game, supports: supports, players: players}} <- check_game_online(payload),
         :ok <- check_remote_game_supports(supports),
         :ok <- check_player_online(players, payload) do
      token()
      |> assign(:game, state.game)
      |> assign(:payload, payload)
      |> payload("send")
      |> broadcast("tells:#{game.short_name}", "tells/receive")

      {:ok, state}
    end
  end

  defp check_payload(event) do
    payload = Map.get(event, "payload", %{})

    case valid_payload?(payload) do
      true ->
        {:ok, payload}

      false ->
        {:error, ~s(invalid payload)}
    end
  end

  defp check_game_online(payload) do
    game =
      Presence.online_games()
      |> Enum.find(&(String.downcase(&1.game.short_name) == String.downcase(payload["to_game"])))

    case game do
      nil ->
        {:error, ~s(game offline)}

      state ->
        {:ok, state}
    end
  end

  defp check_remote_game_supports(supports) do
    case supports_tells?(%{supports: supports}) do
      true ->
        :ok

      false ->
        {:error, ~s(not supported)}
    end
  end

  defp check_player_online(players, payload) do
    players = Enum.map(players, &String.downcase/1)

    case String.downcase(payload["to_name"]) in players do
      true ->
        :ok

      false ->
        {:error, ~s(player offline)}
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
    keys_present? = Enum.sort(Map.keys(payload)) == ["from_name", "message", "sent_at", "to_game", "to_name"]
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

  defmodule View do
    @moduledoc """
    "View" module for tells

    Helps contain what each event looks look as a response
    """

    def payload("send", %{game: game, payload: payload}) do
      %{
        "from_game" => game.short_name,
        "from_name" => payload["from_name"],
        "to_name" => payload["to_name"],
        "sent_at" => payload["sent_at"],
        "message" => payload["message"]
      }
    end
  end
end
