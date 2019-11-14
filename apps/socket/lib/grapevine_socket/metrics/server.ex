defmodule GrapevineSocket.Metrics.Server do
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
    case :pg2.get_closest_pid(GrapevineSocket.Metrics) do
      {:error, _reason} ->
        0

      pid ->
        GenServer.call(pid, {:sockets, :online})
    end
  end

  def init(_) do
    Process.flag(:trap_exit, true)

    :ok = :pg2.create(GrapevineSocket.Metrics)
    :ok = :pg2.join(GrapevineSocket.Metrics, self())

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
    state = Map.put(state, :sockets, List.delete(state.sockets, pid))
    {:noreply, state}
  end
end
