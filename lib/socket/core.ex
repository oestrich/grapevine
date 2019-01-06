defmodule Socket.Core do
  @moduledoc """
  Core events

  Authenticate, heartbeat, etc
  """

  use Web.Socket.Module

  require Logger

  alias Gossip.Applications.Application
  alias Gossip.Channels
  alias Gossip.Presence
  alias Gossip.Text
  alias Socket.Core.Authenticate

  @valid_supports ["achievements", "channels", "games", "players", "tells"]

  @doc """
  Authenticate event

  Possibly disconnects the user invalid

  Event: "authenticate"
  """
  def authenticate(state, %{"payload" => payload}) do
    Authenticate.process(state, payload)
  end

  def authenticate(_state, _), do: :error

  @doc """
  Response to the server sending a heartbeat out

  Event: "heartbeat"
  """
  def heartbeat(state, event) do
    :telemetry.execute([:gossip, :sockets, :heartbeat], 1, %{payload: event["payload"]})

    payload = Map.get(event, "payload", %{})
    players = Map.get(payload, "players", [])

    state =
      state
      |> Map.put(:heartbeat_count, 0)
      |> Map.put(:players, players)

    Presence.update_game(state)

    {:ok, :skip, state}
  end

  @doc """
  Subscribe to a new channel

  Event: "channels/subscribe"
  """
  def channel_subscribe(state, %{"payload" => payload}) do
    with {:ok, channel} <- Map.fetch(payload, "channel"),
         {:ok, channel} <- Channels.ensure_channel(channel),
         {:error, :not_subscribed} <- check_channel_subscribed_to(state, channel) do
      state = Map.put(state, :channels, [channel | state.channels])

      Presence.update_game(state)

      :telemetry.execute([:gossip, :events, :channels, :subscribe], 1, %{channel: channel})
      Web.Endpoint.subscribe("channels:#{channel}")

      {:ok, state}
    else
      {:error, name} ->
        {:error, ~s(Could not subscribe to "#{name}")}

      _ ->
        {:ok, state}
    end
  end

  def channel_subscribe(_state, _event), do: :error

  @doc """
  Unsubscribe from a channel

  Event: "channels/unsubscribe"
  """
  def channel_unsubscribe(state, %{"payload" => payload}) do
    with {:ok, channel} <- Map.fetch(payload, "channel"),
         {:ok, channel} <- check_channel_subscribed_to(state, channel) do
      channels = List.delete(state.channels, channel)
      state = Map.put(state, :channels, channels)

      Presence.update_game(state)

      :telemetry.execute([:gossip, :events, :channels, :unsubscribe], 1, %{channel: channel})
      Web.Endpoint.unsubscribe("channels:#{channel}")

      {:ok, state}
    else
      _ ->
        {:ok, state}
    end
  end

  def channel_unsubscribe(_state, _event), do: :error

  @doc """
  Send a new message over a channel

  Event: "channels/send"
  """
  def channel_send(state, %{"payload" => payload}) do
    :telemetry.execute([:gossip, :events, :channels, :send], 1, %{})

    with {:ok, channel} <- Map.fetch(payload, "channel"),
         {:ok, channel} <- check_channel_subscribed_to(state, channel) do
      name = Text.clean(Map.get(payload, "name", ""))
      message = Text.clean(Map.get(payload, "message", ""))

      token()
      |> assign(:channel, channel)
      |> assign(:game, state.game)
      |> assign(:name, name)
      |> assign(:message, message)
      |> payload("send")
      |> broadcast("channels:#{channel}", "channels/broadcast")

      {:ok, state}
    else
      _ ->
        {:ok, state}
    end
  end

  def channel_send(_state, _event), do: :error

  def valid_support?(support) do
    Enum.member?(@valid_supports, support)
  end

  defp check_channel_subscribed_to(%{game: %Application{}}, channel), do: {:ok, channel}

  defp check_channel_subscribed_to(state, channel) do
    case channel in state.channels do
      true ->
        {:ok, channel}

      false ->
        {:error, :not_subscribed}
    end
  end

  @doc """
  Filter the connected game from the list of games

  Checks the struct for application sockets
  """
  def remove_self_from_game_list(games, state) do
    Enum.reject(games, fn %{game: game} ->
      game.id == state.game.id && game.__struct__ == state.game.__struct__
    end)
  end

  @doc """
  Subscribe to a channel

  Broadcasts back an error if the name was invalid. Use in conjunction with
  `Channels.ensure_channel/1`
  """
  def subscribe_channel({:error, name}) do
    Logger.info("Trying to subscribe to a bad channel")

    token()
    |> assign(:name, name)
    |> event("channel-failure")
    |> relay()
  end

  def subscribe_channel({:ok, channel}) do
    :telemetry.execute([:gossip, :events, :channels, :subscribe], 1, %{channel: channel})
    Web.Endpoint.subscribe("channels:#{channel}")
  end

  defmodule View do
    @moduledoc """
    "View" module for channels

    Helps contain what each event looks look as a response
    """

    def event("channel-failure", %{name: name}) do
      %{
        event: "channels/subscribe",
        status: "failure",
        error: ~s(Could not subscribe to '#{name}'),
      }
    end

    def payload("send", %{channel: channel, game: game, name: name, message: message}) do
      %{
        "channel" => channel,
        "game" => game.short_name,
        "game_id" => game.client_id,
        "name" => name,
        "message" => message,
      }
    end
  end
end
