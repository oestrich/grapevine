defmodule Grapevine.Telnet.Client do
  @moduledoc """
  A client to check for MSSP data
  """

  use GenServer, restart: :transient

  require Logger

  @type message() :: any()
  @type option() :: tuple()
  @type result() :: {:noreply, state()} | {:stop, :normal, state()}
  @type server_options() :: Keyword.t()
  @type state() :: map()
  @type telnet_data() :: binary()

  @doc """
  Callback used during client GenServer initialization

  Add to the GenServer state during this hook
  """
  @callback init(state(), server_options()) :: state()

  @doc """
  Called after the client has connected to the game
  """
  @callback connected(state()) :: :ok

  @doc """
  Handle custom messages sent to the client GenServer

  All unknown messages are sent down into the client callback module
  """
  @callback handle_info(message(), state()) :: result()

  @doc """
  A hook to process telnet options that the general client does not understand

  Specifically to hook into MSSP telnet option data
  """
  @callback process_option(state(), option) :: result()

  @doc """
  New data was received over the telnet connection
  """
  @callback receive(state(), telnet_data()) :: result()

  @doc """
  The TCP connection was dropped
  """
  @callback disconnected(state()) :: :ok

  @do_mssp <<255, 253, 70>>
  @will_charset <<255, 251, 42>>
  @will_term_type <<255, 251, 24>>
  @wont_line_mode <<255, 252, 34>>

  alias Grapevine.Telnet.Options

  def start_link(callback_module, opts) do
    GenServer.start_link(__MODULE__, [module: callback_module] ++ opts)
  end

  def start_link(opts) do
    {server_opts, opts} = Keyword.split(opts, [:name])
    GenServer.start_link(__MODULE__, opts, server_opts)
  end

  defp socket_send(iac, opts) do
    GenServer.cast(self(), {:send, iac, opts})
  end

  def init(opts) do
    module = Keyword.get(opts, :module)

    state = %{
      module: module,
      buffer: <<>>,
      processed: [],
      term_type: :grapevine,
    }

    state = module.init(state, opts)

    :telemetry.execute([:grapevine, :telnet, :start], 1, state)

    {:ok, state, {:continue, :connect}}
  end

  def handle_continue(:connect, state) do
    host = String.to_charlist(state.host)
    {:ok, socket} = :gen_tcp.connect(host, state.port, [:binary, {:packet, :raw}])
    :telemetry.execute([:grapevine, :telnet, :connected], 1, state)
    state.module.connected(state)

    {:noreply, Map.put(state, :socket, socket)}
  end

  def handle_cast({:send, iac, opts}, state) do
    :gen_tcp.send(state.socket, iac)

    case Keyword.has_key?(opts, :telemetry) do
      true ->
        :telemetry.execute([:grapevine, :telnet] ++ opts[:telemetry], 1, Keyword.get(opts, :metadata, %{}))

      false ->
        :ok
    end

    {:noreply, state}
  end

  def handle_info({:tcp, _port, data}, state) do
    {options, string, buffer} = Options.parse(state.buffer <> data)
    state = %{state | buffer: buffer}

    Enum.each(options, fn option ->
      send(self(), {:process, option})
    end)

    state.module.receive(state, string)
  end

  def handle_info({:tcp_closed, _port}, state) do
    state.module.disconnected(state)
    {:stop, :normal, state}
  end

  def handle_info({:process, option}, state) do
    case already_processed?(state, option) do
      true ->
        {:noreply, state}

      false ->
        process_option(state, option)
    end
  end

  def handle_info(message, state) do
    state.module.handle_info(message, state)
  end

  defp process_option(state, option = {:will, :mssp}) do
    socket_send(@do_mssp, telemetry: [:mssp, :sent])

    {:noreply, %{state | processed: [option | state.processed]}}
  end

  defp process_option(state, option = {:will, :gmcp}) do
    socket_send(<<255, 253, 201>>, telemetry: [:gmcp, :sent])
    hello = Jason.encode!(%{client: "Grapevine", version: Grapevine.version()})
    socket_send(<<255, 250, 201>> <> "Core.Hello #{hello}" <> <<255, 240>>, [])
    {:noreply, %{state | processed: [option | state.processed]}}
  end

  defp process_option(state, option = {:will, byte}) when is_integer(byte) do
    socket_send(<<255, 254, byte>>, telementry: [:wont], metadata: %{byte: byte})
    {:noreply, %{state | processed: [option | state.processed]}}
  end

  defp process_option(state, option = {:do, :term_type}) do
    socket_send(@will_term_type, telemetry: [:term_type, :sent])
    {:noreply, %{state | processed: [option | state.processed]}}
  end

  defp process_option(state, option = {:do, :charset}) do
    socket_send(@will_charset, telemetry: [:charset, :sent])
    {:noreply, %{state | processed: [option | state.processed]}}
  end

  defp process_option(state, option = {:do, :line_mode}) do
    socket_send(@wont_line_mode, telemetry: [:line_mode, :sent])
    {:noreply, %{state | processed: [option | state.processed]}}
  end

  defp process_option(state, option = {:do, byte}) when is_integer(byte) do
    socket_send(<<255, 252, byte>>, telemetry: [:dont], metadata: %{byte: byte})
    {:noreply, %{state | processed: [option | state.processed]}}
  end

  defp process_option(state, {:charset, :request, sep, charsets}) do
    charsets =
      charsets
      |> String.split(sep)
      |> Enum.map(&String.downcase/1)

    case Enum.member?(charsets, "utf-8") do
      true ->
        socket_send(<<255, 250, 42, 2>> <> "UTF-8" <> <<255, 240>>, telemetry: [:charset, :accepted])
        {:noreply, state}

      _ ->
        socket_send(<<255, 250, 42, 3, 255, 240>>, telemetry: [:charset, :rejected])
        {:noreply, state}
    end
  end

  #   1 "ANSI"              Client supports all common ANSI color codes.
  #   2 "VT100"             Client supports all common VT100 codes.
  #   4 "UTF-8"             Client is using UTF-8 character encoding.
  #   8 "256 COLORS"        Client supports all 256 color codes.
  #  16 "MOUSE TRACKING"    Client supports xterm mouse tracking.
  #  32 "OSC COLOR PALETTE" Client supports the OSC color palette.
  #  64 "SCREEN READER"     Client is using a screen reader.
  # 128 "PROXY"             Client is a proxy allowing different users to connect from the same IP address.
  # 256 "TRUECOLOR"         Client supports all truecolor codes.
  defp process_option(state, {:send, :term_type}) do
    start_term_type = <<255, 250, 24, 0>>
    end_term_type = <<255, 240>>

    mtts = 1 + 2 + 4 + 8 + 128 + 256

    case state.term_type do
      :grapevine ->
        socket_send(start_term_type <> "Grapevine" <> end_term_type, telemetry: [:term_type, :details])
        state = %{state | term_type: :ansi}
        {:noreply, state}

      :ansi ->
        socket_send(start_term_type <> "ANSI-256COLOR" <> end_term_type, telemetry: [:term_type, :details])
        state = %{state | term_type: :mtts}
        {:noreply, state}

      :mtts ->
        socket_send(start_term_type <> "MTTS #{mtts}" <> end_term_type, telemetry: [:term_type, :details])
        {:noreply, state}
    end
  end

  defp process_option(state, option = {:gmcp, _, _}) do
    state.module.process_option(state, option)
  end

  defp process_option(state, option) do
    state = %{state | processed: [option | state.processed]}
    state.module.process_option(state, option)
  end

  defp already_processed?(state, option) do
    Enum.member?(state.processed, option)
  end
end
