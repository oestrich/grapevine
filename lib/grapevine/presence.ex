defmodule Grapevine.Presence do
  @moduledoc """
  Local cache of the presence data from `Socket.Presence`
  """

  use GenServer

  alias Grapevine.Presence.Client

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def online_games() do
    Client.online_games()
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
