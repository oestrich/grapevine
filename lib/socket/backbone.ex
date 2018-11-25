defmodule Socket.Backbone do
  @moduledoc """
  Backbone processing for application sockets

  Backbone events:
  - "channels/new", payload is the new channel
  - "games/new", payload is the new game
  - "games/edit", payload is the updated game

  Sync events:
  - "sync/channels", Sync a list of channels
  - "sync/games", Sync a list of games
  """

  use Web.Socket.Module

  alias Gossip.Applications.Application
  alias Gossip.Channels
  alias Gossip.Versions

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
  def process_event(state, %{event: "channels/new", payload: version}) do
    Web.Endpoint.subscribe("channels:#{version.payload.name}")
    broadcast_channels([version])
    {:ok, state}
  end

  def process_event(state, %{event: "events/new", payload: version}) do
    broadcast_events([version])
    {:ok, state}
  end

  def process_event(state, %{event: "events/edit", payload: version}) do
    broadcast_events([version])
    {:ok, state}
  end

  def process_event(state, %{event: "events/delete", payload: version}) do
    broadcast_events([version])
    {:ok, state}
  end

  def process_event(state, %{event: "games/new", payload: version}) do
    broadcast_games([version])
    {:ok, state}
  end

  def process_event(state, %{event: "games/edit", payload: version}) do
    broadcast_games([version])
    {:ok, state}
  end

  def process_event(state, _message), do: {:ok, state}

  @doc """
  Process a sync frame
  """
  def sync(state, %{"event" => "sync", "payload" => payload}) do
    since = Map.get(payload, "since")
    sync_channels(since)
    sync_games(since)
    {:ok, state}
  end

  @doc """
  If the connected game is a system application, perform extra finalizations

  - Subscribe to all channels
  - Listen to new channels
  """
  def maybe_finalize_authenticate(state) do
    with {:ok, :application} <- check_for_application(state) do
      subscribe_to_backbone()
      subscribe_to_all()
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
  def sync_channels(since \\ nil) do
    "channels"
    |> Versions.for(since)
    |> Enum.chunk_every(10)
    |> Enum.each(&broadcast_channels/1)
  end

  defp broadcast_channels(versions) do
    token()
    |> assign(:versions, versions)
    |> event("sync/channels")
    |> relay()
  end

  @doc """
  Send batches of `sync/games` events to newly connected sockets
  """
  def sync_games(since \\ nil) do
    "games"
    |> Versions.for(since)
    |> Enum.chunk_every(10)
    |> Enum.each(&broadcast_games/1)
  end

  defp broadcast_games(versions) do
    token()
    |> assign(:versions, versions)
    |> event("sync/games")
    |> relay()
  end

  defp broadcast_events(versions) do
    token()
    |> assign(:versions, versions)
    |> event("sync/events")
    |> relay()
  end

  defmodule View do
    @moduledoc """
    "View" module for backbone events
    """

    def event("versions", %{event: event, versions: versions}) do
      payload =
        Enum.map(versions, fn version ->
          Map.take(version, [:action, :payload, :logged_at])
        end)

      %{
        event: event,
        ref: UUID.uuid4(),
        payload: payload,
      }
    end

    def event("sync/channels", %{versions: versions}) do
      event("versions", %{event: "sync/channels", versions: versions})
    end

    def event("sync/events", %{versions: versions}) do
      event("versions", %{event: "sync/events", versions: versions})
    end

    def event("sync/games", %{versions: versions}) do
      event("versions", %{event: "sync/games", versions: versions})
    end
  end
end
