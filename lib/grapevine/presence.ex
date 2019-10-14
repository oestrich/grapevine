defmodule Grapevine.Presence do
  @moduledoc """
  Local cache of the presence data from `Socket.Presence`
  """

  use GenServer

  alias GrapevineData.Games
  alias Grapevine.Presence.Client

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  @doc """
  Return a list of all games that are considered online
  """
  def online_games() do
    Client.online_games()
  end

  @doc """
  Return a random game that is online
  """
  def random_online_game() do
    game =
      online_games()
      |> Enum.map(& &1.game)
      |> Enum.shuffle()
      |> List.first()

    case is_nil(game) do
      true ->
        :error

      false ->
        {:ok, game}
    end
  end

  @doc """
  Return a random game that is online and has the web client enabled
  """
  def random_online_web_game() do
    game =
      online_games()
      |> Enum.map(& &1.game)
      |> Enum.filter(&web_client_enabled?/1)
      |> Enum.shuffle()
      |> List.first()

    case is_nil(game) do
      true ->
        :error

      false ->
        {:ok, game}
    end
  end

  defp web_client_enabled?(%{enable_web_client: false}), do: false

  defp web_client_enabled?(game = %{enable_web_client: true}) do
    case Games.get_web_client_connection(game) do
      {:ok, _connection} ->
        true

      {:error, :not_found} ->
        false
    end
  end

  def init(_) do
    Client.create_table()
    {:ok, %{}, {:continue, :subscribe}}
  end

  def handle_continue(:subscribe, state) do
    Web.Endpoint.subscribe("game:presence")
    {:noreply, state}
  end

  def handle_info(%{topic: "game:presence", event: "games/update", payload: presence}, state) do
    Client.update_presence(presence)
    {:noreply, state}
  end
end
