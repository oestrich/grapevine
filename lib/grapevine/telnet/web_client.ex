defmodule Grapevine.Telnet.WebClient do
  @moduledoc """
  Callbacks for specifically checking MSSP data
  """

  require Logger

  alias Grapevine.Telnet.Client
  alias Grapevine.Telnet.ClientSupervisor
  alias Grapevine.Telnet.Features

  @behaviour Client

  @idle_time 15_000

  def recv(pid, message) do
    send(pid, {:recv, message})
  end

  def connect(user, opts) do
    case :global.whereis_name(pid(user, opts)) do
      :undefined ->
        ClientSupervisor.start_client(__MODULE__, opts ++ [name: {:global, pid(user, opts)}])

      pid ->
        set_channel(pid, opts[:channel_pid])
        {:ok, pid}
    end
  end

  defp pid(user, opts) do
    {:webclient, {user.id, Keyword.fetch!(opts, :game_id)}}
  end

  defp set_channel(pid, channel_pid) do
    send(pid, {:set, :channel_pid, channel_pid})
  end

  @impl true
  def init(state, opts) do
    # Link against the channel process, then trap exits to know
    # when the channel process is killed.
    channel_pid = Keyword.get(opts, :channel_pid)
    Process.flag(:trap_exit, true)
    Process.link(channel_pid)

    Metrics.Server.client_online()

    state
    |> Map.put(:host, Keyword.get(opts, :host))
    |> Map.put(:port, Keyword.get(opts, :port))
    |> Map.put(:channel_pid, channel_pid)
    |> Map.put(:channel_buffer, <<>>)
  end

  @impl true
  def connected(state) do
    maybe_forward(state, :echo, "\e[32mConnected.\e[0m\n")
  end

  @impl true
  def connection_failed(state, :econnrefused) do
    maybe_forward(state, :echo, "\e[31mConnection refused.\e[0m\n")
  end

  def connection_failed(state, _) do
    maybe_forward(state, :echo, "\e[31mConnection failed.\e[0m\n")
  end

  @impl true
  def disconnected(state) do
    maybe_forward(state, :echo, "\e[31mDisconnected.\e[0m\n")
  end

  @impl true
  def process_option(state = %{features: %{gmcp: true}}, {:gmcp, message, data}) do
    Logger.info("Received GMCP message #{message}")

    case Features.message_enabled?(state, message) do
      true ->
        maybe_forward(state, :gmcp, {message, data})
        {:noreply, state}

      false ->
        {:noreply, state}
    end
  end

  def process_option(state, _option), do: {:noreply, state}

  @impl true
  def receive(state, data) do
    maybe_forward(state, :echo, data)

    buffer = String.split(state.channel_buffer <> data, "\n")
    buffer =
      buffer
      |> Enum.take(-20)
      |> Enum.join("\n")

    {:noreply, %{state | channel_buffer: buffer}}
  end

  @impl true
  def handle_info({:recv, message}, state) do
    :gen_tcp.send(state.socket, message)

    {:noreply, state}
  end

  def handle_info({:set, :channel_pid, channel_pid}, state) do
    if state.channel_pid != nil do
      Process.unlink(state.channel_pid)
    end
    Process.link(channel_pid)

    state = Map.put(state, :channel_pid, channel_pid)
    connected(state)
    maybe_forward(state, :echo, state.channel_buffer)

    {:noreply, state}
  end

  def handle_info({:EXIT, pid, _reason}, state) do
    case state.channel_pid == pid do
      true ->
        Process.send_after(self(), {:idle, :disconnect}, @idle_time)
        state = Map.put(state, :channel_pid, nil)
        {:noreply, state}

      false ->
        {:noreply, state}
    end
  end

  def handle_info({:idle, :disconnect}, state) do
    case is_nil(state.channel_pid) do
      true ->
        Logger.debug("Shutting down the client due to idle", type: :telnet)

        {:stop, :normal, state}

      false ->
        {:noreply, state}
    end
  end

  defp maybe_forward(state = %{channel_pid: channel_pid}, :echo, data) when channel_pid != nil do
    send(state.channel_pid, {:echo, String.replace(data, "\r", "")})
  end

  defp maybe_forward(state = %{channel_pid: channel_pid}, :gmcp, {module, data}) when channel_pid != nil do
    send(state.channel_pid, {:gmcp, module, data})
    :ok
  end

  defp maybe_forward(_state, _type, _data), do: :ok
end
