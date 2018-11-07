defmodule Metrics.Server do
  @moduledoc """
  Small gen server to tick and record gauge metrics
  """

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Get the count of online sockets
  """
  @spec online_sockets() :: integer()
  def online_sockets() do
    GenServer.call(__MODULE__, {:sockets, :online})
  end

  @doc """
  Let the server know a socket came online
  """
  def socket_online() do
    GenServer.cast(__MODULE__, {:socket, :online, self()})
  end

  def init(_) do
    Process.flag(:trap_exit, true)
    {:ok, %{sockets: []}}
  end

  def handle_call({:sockets, :online}, _from, state) do
    {:reply, length(state.sockets), state}
  end

  def handle_cast({:socket, :online, pid}, state) do
    Process.link(pid)
    {:noreply, Map.put(state, :sockets, [pid | state.sockets])}
  end

  def handle_info({:EXIT, pid, _reason}, state) do
    {:noreply, Map.put(state, :sockets, List.delete(state.sockets, pid))}
  end
end
