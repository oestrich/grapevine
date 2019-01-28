defmodule Grapevine.Telnet.WebClient do
  @moduledoc """
  Callbacks for specifically checking MSSP data
  """

  require Logger

  alias Grapevine.Telnet.Client

  @behaviour Client

  def recv(pid, message) do
    send(pid, {:recv, message})
  end

  def start_link(opts) do
    Client.start_link(__MODULE__, opts)
  end

  @impl true
  def init(state, opts) do
    state
    |> Map.put(:host, Keyword.get(opts, :host))
    |> Map.put(:port, Keyword.get(opts, :port))
    |> Map.put(:channel_pid, Keyword.get(opts, :channel_pid))
  end

  @impl true
  def connected(state) do
    send(state.channel_pid, {:echo, "\e[32mConnected.\e[0m\n"})

    :ok
  end

  @impl true
  def process_option(state, _option), do: {:noreply, state}

  @impl true
  def receive(state, data) do
    send(state.channel_pid, {:echo, String.replace(data, "\r", "")})

    {:noreply, state}
  end

  @impl true
  def handle_info({:recv, message}, state) do
    :gen_tcp.send(state.socket, message)

    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
