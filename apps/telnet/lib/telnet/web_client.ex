defmodule GrapevineTelnet.WebClient do
  @moduledoc """
  Callbacks for specifically checking MSSP data
  """

  require Logger

  alias GrapevineTelnet.Client
  alias GrapevineTelnet.ClientSupervisor
  alias GrapevineTelnet.Features
  alias GrapevineTelnet.Presence
  alias GrapevineTelnet.PubSub
  alias Telnet.NewEnviron

  @behaviour Client

  @idle_time 60_000

  def recv(pid, message) do
    send(pid, {:recv, message})
  end

  def event(pid, type, payload) do
    send(pid, {:event, type, payload})
  end

  def connect(session_token, opts) do
    case :global.whereis_name(pid(session_token, opts)) do
      :undefined ->
        ClientSupervisor.start_client(
          __MODULE__,
          opts ++ [name: {:global, pid(session_token, opts)}]
        )

      pid ->
        set_channel(pid, opts[:channel_pid])
        {:ok, pid}
    end
  end

  defp pid(session_token, opts) do
    {:webclient, {session_token, Keyword.fetch!(opts, :game).id}}
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

    Presence.client_online(state.sid, opts)
    PubSub.subscribe("system")

    state
    |> Map.put(:game, Keyword.get(opts, :game))
    |> Map.put(:settings, Keyword.get(opts, :client_settings))
    |> Map.put(:type, Keyword.get(opts, :type))
    |> Map.put(:host, Keyword.get(opts, :host))
    |> Map.put(:port, Keyword.get(opts, :port))
    |> Map.put(:client_ip, Keyword.get(opts, :client_ip))
    |> Map.put(:certificate, Keyword.get(opts, :certificate))
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

  def connection_failed(state, {:tls_alert, 'handshake failure'}) do
    maybe_forward(state, :echo, "\e[31mInvalid certificate.\e[0m\n")
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
    state = process_gmcp_message(state, message, data)

    case Features.message_enabled?(state, message) do
      true ->
        Logger.debug(
          fn ->
            "Received GMCP message #{message}"
          end,
          type: :telnet
        )

        maybe_forward(state, :gmcp, {message, data})
        state = Features.cache_message(state, message, data)

        {:noreply, state}

      false ->
        Logger.debug(
          fn ->
            "Received unknown GMCP message #{message}"
          end,
          type: :telnet
        )

        {:noreply, state}
    end
  end

  # the game is handling echos, aka password prompt
  def process_option(state, {:will, :echo}) do
    # Send back DO ECHO
    Client.socket_send(<<255, 253, 1>>, [])
    maybe_forward(state, :option, {:prompt_type, "password"})
    {:noreply, state}
  end

  # password is over
  def process_option(state, {:wont, :echo}) do
    # Send back DONT ECHO
    Client.socket_send(<<255, 254, 1>>, [])
    maybe_forward(state, :option, {:prompt_type, "text"})
    {:noreply, state}
  end

  def process_option(state, {:ga}) do
    maybe_forward(state, :ga)
    {:noreply, state}
  end

  def process_option(state, {:oauth, message, data}) do
    maybe_forward(state, :oauth, {message, data})
    {:noreply, state}
  end

  def process_option(state, {:do, :new_environ}) do
    case state.settings.new_environ_enabled do
      true ->
        will_new_environ = <<255, 251, 39>>
        Client.socket_send(will_new_environ)
        {:noreply, state}

      false ->
        wont_new_environ = <<255, 252, 39>>
        Client.socket_send(wont_new_environ)
        {:noreply, state}
    end
  end

  def process_option(state, {:new_environ, :send, variables}) do
    case state.settings.new_environ_enabled do
      true ->
        respond_to_new_environ(state, variables)

      false ->
        {:noreply, state}
    end
  end

  def process_option(state, _option), do: {:noreply, state}

  def respond_to_new_environ(state, []) do
    client_ip = to_string(:inet_parse.ntoa(state.client_ip))
    response = NewEnviron.encode(:is, [{"IPADDRESS", client_ip}])
    Client.socket_send(response)
    {:noreply, state}
  end

  def respond_to_new_environ(state, variables) do
    case "IPADDRESS" in variables do
      true ->
        respond_to_new_environ(state, [])

      false ->
        Client.socket_send(NewEnviron.encode(:is, []))
        {:noreply, state}
    end
  end

  @doc """
  Globally process a GMCP message

  If the message matches the character message in the web client settings, then
  record the name and update presence with it.
  """
  def process_gmcp_message(state, message, data) do
    case state.settings.character_message == message do
      true ->
        player_name = Map.get(data, state.settings.character_name_path)
        Presence.set_player_name(player_name)
        state

      false ->
        state
    end
  end

  @impl true
  def receive(state, "") do
    {:noreply, state}
  end

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
    Client.socket_send(message, [])
    Presence.socket_sent()
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

    rebroadcast_gmcp(state)

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

  def handle_info({:event, "oauth", payload}, state) do
    case payload.type do
      "AuthorizationGrant" ->
        params = %{
          state: payload.state,
          code: payload.code
        }

        message =
          <<255, 250, 165>> <> "AuthorizationGrant " <> Jason.encode!(params) <> <<255, 240>>

        Client.socket_send(message, [])

        {:noreply, state}

      _ ->
        {:noreply, state}
    end
  end

  def handle_info({:event, "system/disconnect", _payload}, state) do
    disconnected(state)
    {:stop, :normal, state}
  end

  def handle_info(%{topic: "system", event: "restart"}, state) do
    message = """
    \e[31;1m\nSYSTEM:\e[37;1m The Grapevine web application will be restarting shortly.\e[0m
    \e[31;1mSYSTEM:\e[37;1m Your session will not be disconnected.\e[0m
    """

    maybe_forward(state, :echo, message)
    {:noreply, state}
  end

  defp rebroadcast_gmcp(state = %{features: %{gmcp: true}}) do
    Enum.each(state.features.message_cache, fn {message, data} ->
      maybe_forward(state, :gmcp, {message, data})
    end)
  end

  defp rebroadcast_gmcp(_state), do: :ok

  defp maybe_forward(state = %{channel_pid: channel_pid}, :echo, data) when channel_pid != nil do
    send(state.channel_pid, {:echo, String.replace(data, "\r", "")})
  end

  defp maybe_forward(state = %{channel_pid: channel_pid}, :gmcp, {module, data})
       when channel_pid != nil do
    send(state.channel_pid, {:gmcp, module, data})
  end

  defp maybe_forward(state = %{channel_pid: channel_pid}, :oauth, {module, data})
       when channel_pid != nil do
    send(state.channel_pid, {:oauth, module, data})
  end

  defp maybe_forward(state = %{channel_pid: channel_pid}, :option, {key, value})
       when channel_pid != nil do
    send(state.channel_pid, {:option, key, value})
  end

  defp maybe_forward(_state, _type, _data), do: :ok

  defp maybe_forward(state = %{channel_pid: channel_pid}, :ga) when channel_pid != nil do
    send(state.channel_pid, {:ga})
  end

  defp maybe_forward(_state, _type), do: :ok
end
