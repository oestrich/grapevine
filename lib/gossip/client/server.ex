defmodule Gossip.Client.Server do
  @moduledoc """
  A local fake "client" to the socket
  """

  use GenServer

  alias Gossip.Client.Server.State
  alias Gossip.Client.Tells

  defmodule State do
    @moduledoc """
    State for the local client
    """

    defstruct []
  end

  @doc """
  Send a tell to a game
  """
  def send_tell(to_game, to_player, message) do
    Web.Endpoint.broadcast("tells:#{to_game}", "tells/receive", %{
      from_game: "gossip",
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
    Web.Endpoint.subscribe("tells:gossip")
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
