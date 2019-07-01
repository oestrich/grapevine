defmodule Grapevine.Client.Server do
  @moduledoc """
  A local fake "client" to the socket
  """

  use GenServer

  alias Grapevine.Client.Server.State
  alias Grapevine.Client.Tells
  alias GrapevineData.Messages

  @behaviour Grapevine.Client

  @client_id "grapevine-id"

  defmodule State do
    @moduledoc """
    State for the local client
    """

    defstruct []
  end

  @impl true
  def broadcast(message) do
    %{channel: channel, user: user, message: message} = message

    Web.Endpoint.broadcast("channels:#{channel.name}", "channels/broadcast", %{
      "channel" => channel.name,
      "game" => "Grapevine",
      "game_id" => @client_id,
      "name" => user.username,
      "message" => message
    })

    Web.Endpoint.broadcast("chat:#{channel.name}", "broadcast", %{
      "channel" => channel.name,
      "game" => "Grapevine",
      "name" => user.username,
      "message" => message
    })

    Messages.record_web(channel, user, message)

    :ok
  end

  @impl true
  def send_tell(to_game, to_player, message) do
    Web.Endpoint.broadcast("tells:#{to_game}", "tells/receive", %{
      from_game: "grapevine",
      from_name: "system",
      to_name: to_player,
      sent_at: Timex.now(),
      message: message
    })

    :ok
  end

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  @impl true
  def init(_) do
    {:ok, %State{}, {:continue, {:subscribe}}}
  end

  @impl true
  def handle_continue({:subscribe}, state) do
    Web.Endpoint.subscribe("tells:grapevine")
    {:noreply, state}
  end

  @impl true
  def handle_info(event = %Phoenix.Socket.Broadcast{event: "tells/receive"}, state) do
    receive_tell(event.payload)

    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp receive_tell(%{"from_game" => from_game, "from_name" => from_player, "message" => message}) do
    Tells.receive_tell(from_game, from_player, message)
  end

  defp receive_tell(_), do: :ok
end
