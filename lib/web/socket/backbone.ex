defmodule Web.Socket.Backbone do
  @moduledoc """
  Backbone processing for application sockets

  Backbone events:
  - "channels/new", payload is the new channel

  Sync events:
  - "sync/channels", Sync a list of channels
  """

  use Web.Socket.Module

  alias Gossip.Applications.Application
  alias Gossip.Channels
  alias Gossip.Games
  alias Web.GameView

  @doc """
  Process a system backbone message

  Gates the state for a connected application before processing
  """
  def handle_event(state, message) do
    with {:ok, :application} <- check_for_application(state) do
      process_event(state, message)
    else
      _ ->
        {:ok, state}
    end
  end

  @doc """
  Process a system backbone message
  """
  def process_event(state, message = %{event: "channels/new"}) do
    Web.Endpoint.subscribe("channels:#{message.payload.name}")
    broadcast_channels([message.payload])
    {:ok, state}
  end

  def process_event(state, message = %{event: "games/new"}) do
    broadcast_games([message.payload])
    {:ok, state}
  end

  def process_event(state, message = %{event: "games/edit"}) do
    broadcast_games([message.payload])
    {:ok, state}
  end

  def process_event(state, _message), do: {:ok, state}

  @doc """
  If the connected game is a system application, perform extra finalizations

  - Subscribe to all channels
  - Listen to new channels
  """
  def maybe_finalize_authenticate(state) do
    with {:ok, :application} <- check_for_application(state) do
      subscribe_to_backbone()
      subscribe_to_all()
      sync_channels()
      sync_games()
    end
  end

  defp check_for_application(state) do
    case state.game do
      %Application{} ->
        {:ok, :application}

      _ ->
        {:error, :not_application}
    end
  end

  defp subscribe_to_backbone() do
    Web.Endpoint.subscribe("system:backbone")
  end

  defp subscribe_to_all() do
    channels = Channels.all(include_hidden: true)
    Enum.each(channels, fn channel ->
      Web.Endpoint.subscribe("channels:#{channel.name}")
    end)
  end

  @doc """
  Send batches of `sync/channels` events to newly connected sockets
  """
  def sync_channels() do
    channels = Channels.all(include_hidden: true)

    channels
    |> Enum.chunk_every(10)
    |> Enum.each(&broadcast_channels/1)
  end

  defp broadcast_channels(channels) do
    token()
    |> assign(:channels, channels)
    |> event("sync/channels")
    |> relay()
  end

  @doc """
  Send batches of `sync/games` events to newly connected sockets
  """
  def sync_games() do
    Games.all()
    |> Enum.chunk_every(10)
    |> Enum.each(&broadcast_games/1)
  end

  defp broadcast_games(games) do
    token()
    |> assign(:games, games)
    |> event("sync/games")
    |> relay()
  end

  defmodule View do
    @moduledoc """
    "View" module for backbone events
    """

    def event("sync/channels", %{channels: channels}) do
      payload =
        Enum.map(channels, fn channel ->
          Map.take(channel, [:id, :name, :description, :hidden])
        end)

      %{
        event: "sync/channels",
        ref: UUID.uuid4(),
        payload: %{channels: payload},
      }
    end

    def event("sync/games", %{games: games}) do
      payload =
        Enum.map(games, fn game ->
          GameView.render("sync.json", %{game: game})
        end)

      %{
        event: "sync/games",
        ref: UUID.uuid4(),
        payload: %{games: payload},
      }
    end
  end
end
