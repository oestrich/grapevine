defmodule Gossip.Telnet.Worker do
  @moduledoc """
  Cron worker for checking telnet connection
  """

  use GenServer

  alias Gossip.Games
  alias Gossip.Telnet.Client

  @initial_delay 60 * 1000
  @one_hour 60 * 60 * 1000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(_) do
    schedule_check(@initial_delay)
    Process.flag(:trap_exit, true)
    {:ok, %{}}
  end

  def handle_info({:record}, state) do
    Games.telnet_connections()
    |> Enum.each(fn connection ->
      Client.start_link([type: :record, connection: connection])
    end)

    schedule_check()

    {:noreply, state}
  end

  def handle_info({:EXIT, _pid, _reason}, state) do
    {:noreply, state}
  end

  defp schedule_check(delay \\ @one_hour) do
    Process.send_after(self(), {:record}, delay)
  end
end
