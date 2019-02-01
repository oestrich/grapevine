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
  Get the count of online clients
  """
  @spec online_clients() :: integer()
  def online_clients() do
    GenServer.call(__MODULE__, {:clients, :online})
  end

  @doc """
  Let the server know a socket came online
  """
  def socket_online() do
    GenServer.cast(__MODULE__, {:socket, :online, self()})
  end

  @doc """
  Let the server know a web client came onlin
  """
  def client_online() do
    GenServer.cast(__MODULE__, {:client, :online, self()})
  end

  def init(_) do
    Process.flag(:trap_exit, true)
    {:ok, %{sockets: [], clients: []}}
  end

  def handle_call({:sockets, :online}, _from, state) do
    {:reply, length(state.sockets), state}
  end

  def handle_call({:clients, :online}, _from, state) do
    {:reply, length(state.clients), state}
  end

  def handle_cast({:socket, :online, pid}, state) do
    Process.link(pid)
    {:noreply, Map.put(state, :sockets, [pid | state.sockets])}
  end

  def handle_cast({:client, :online, pid}, state) do
    Process.link(pid)
    {:noreply, Map.put(state, :clients, [pid | state.clients])}
  end

  def handle_info({:EXIT, pid, _reason}, state) do
    state =
      state
      |> Map.put(:sockets, List.delete(state.sockets, pid))
      |> Map.put(:clients, List.delete(state.clients, pid))

    {:noreply, state}
  end
end
