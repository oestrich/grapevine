defmodule Grapevine.Telnet.Client do
  @moduledoc """
  A client to check for MSSP data
  """

  use GenServer

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

  @do_mssp <<255, 253, 70>>
  @will_term_type <<255, 251, 24>>
  @term_type <<255, 250, 24, 0>> <> "Grapevine" <> <<255, 240>>
  @wont_line_mode <<255, 252, 34>>

  alias Grapevine.Telnet.Options

  def start_link(callback_module, opts) do
    GenServer.start_link(__MODULE__, [module: callback_module] ++ opts)
  end

  defp socket_send(iac, opts \\ []) do
    GenServer.cast(self(), {:send, iac, opts})
  end

  def init(opts) do
    module = Keyword.get(opts, :module)

    state = %{
      module: module,
      buffer: <<>>,
      processed: []
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
        :telemetry.execute([:grapevine, :telnet] ++ opts[:telemetry], 1, state)

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

  defp process_option(state, option = {:do, :term_type}) do
    socket_send(@will_term_type, telemetry: [:term_type, :sent])
    socket_send(@term_type)

    {:noreply, %{state | processed: [option | state.processed]}}
  end

  defp process_option(state, option = {:do, :line_mode}) do
    socket_send(@wont_line_mode, telemetry: [:line_mode, :sent])

    {:noreply, %{state | processed: [option | state.processed]}}
  end

  defp process_option(state, option) do
    state = %{state | processed: [option | state.processed]}
    state.module.process_option(state, option)
  end

  defp already_processed?(state, option) do
    Enum.member?(state.processed, option)
  end
end
