defmodule Metrics.Server do
  @moduledoc """
  Small gen server to tick and record gauge metrics
  """

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  @doc """
  Get the count of online sockets
  """
  @spec online_sockets() :: integer()
  def online_sockets() do
    case :pg2.get_closest_pid(Grapevine.Metrics) do
      {:error, _reason} ->
        0

      pid ->
        GenServer.call(pid, {:sockets, :online})
    end
  end

  @doc """
  Get the count of online clients
  """
  @spec online_clients() :: integer()
  def online_clients() do
    case :pg2.get_closest_pid(Grapevine.Metrics) do
      {:error, _reason} ->
        0

      pid ->
        GenServer.call(pid, {:clients, :online})
    end
  end

  def init(_) do
    Process.flag(:trap_exit, true)

    :ok = :pg2.create(Grapevine.Metrics)
    :ok = :pg2.join(Grapevine.Metrics, self())

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
