defmodule Metrics.Server do
  @moduledoc """
  Small gen server to tick and record gauge metrics
  """

  use GenServer

  alias Gossip.Presence
  alias Metrics.GameInstrumenter

  @update_interval 10_000

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    :timer.send_interval(@update_interval, {:update})
    {:ok, %{}}
  end

  def handle_info({:update}, state) do
    Presence.online_games()
    |> length()
    |> GameInstrumenter.set_games()

    {:noreply, state}
  end
end
