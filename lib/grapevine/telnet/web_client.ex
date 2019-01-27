defmodule Grapevine.Telnet.WebClient do
  @moduledoc """
  Callbacks for specifically checking MSSP data
  """

  require Logger

  alias Grapevine.Telnet.Client

  @behaviour Client

  def start_link(opts) do
    Client.start_link(__MODULE__, opts)
  end

  @impl true
  def init(state, opts) do
    state
    |> Map.put(:host, Keyword.get(opts, :host))
    |> Map.put(:port, Keyword.get(opts, :port))
    |> Map.put(:socket_pid, Keyword.get(opts, :socket_pid))
  end

  @impl true
  def process_option(state, _option), do: {:noreply, state}

  @impl true
  def receive(state, data) do
    send(state.socket_pid, {:echo, data})

    {:noreply, state}
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end
end
