defmodule Metrics.Server do
  @moduledoc """
  Small gen server to tick and record gauge metrics
  """

  use GenServer

  alias Metrics.SocketInstrumenter

  @update_interval 10_000

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Let the server know a socket came online
  """
  def socket_online() do
    GenServer.cast(__MODULE__, {:socket, :online, self()})
  end

  def init(_) do
    :timer.send_interval(@update_interval, {:update})
    Process.flag(:trap_exit, true)
    {:ok, %{sockets: []}}
  end

  def handle_cast({:socket, :online, pid}, state) do
    Process.link(pid)
    {:noreply, Map.put(state, :sockets, [pid | state.sockets])}
  end

  def handle_info({:EXIT, pid, _reason}, state) do
    {:noreply, Map.put(state, :sockets, List.delete(state.sockets, pid))}
  end

  def handle_info({:update}, state) do
    state.sockets
    |> length()
    |> SocketInstrumenter.set_sockets()

    {:noreply, state}
  end
end
