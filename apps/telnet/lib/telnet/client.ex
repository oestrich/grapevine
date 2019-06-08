defmodule GrapevineTelnet.Client do
  @moduledoc """
  A client to check for MSSP data
  """

  use GenServer, restart: :transient

  require Logger

  alias GrapevineTelnet.Features
  alias Telnet.Options

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
  Called after the client could not connect to the remote game
  """
  @callback connection_failed(state(), reason :: atom()) :: :ok

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

  def start_link(callback_module, opts) do
    GenServer.start_link(__MODULE__, [module: callback_module] ++ opts)
  end

  def start_link(opts) do
    {server_opts, opts} = Keyword.split(opts, [:name])
    GenServer.start_link(__MODULE__, opts, server_opts)
  end

  @doc """
  Send data back to the server through the socket

  Note: This uses self()
  """
  def socket_send(data, opts \\ []) do
    GenServer.cast(self(), {:send, data, opts})
  end

  def init(opts) do
    module = Keyword.get(opts, :module)

    state = %{
      sid: UUID.uuid4(),
      module: module,
      buffer: <<>>,
      processed: [],
      features: %Features{},
      term_type: :grapevine
    }

    state = module.init(state, opts)

    :telemetry.execute([:telnet, :start], %{count: 1}, state)

    {:ok, state, {:continue, :connect}}
  end

  def handle_continue(:connect, state) do
    case connect(state) do
      {:ok, socket} ->
        :telemetry.execute([:telnet, :connection, :connected], %{count: 1}, state)
        state.module.connected(state)

        {:noreply, Map.put(state, :socket, socket)}

      {:error, error} ->
        state.module.connection_failed(state, error)
        :telemetry.execute([:telnet, :connection, :failed], %{count: 1}, %{error: error})

        {:stop, :normal, state}
    end
  end

  def handle_cast({:send, iac, opts}, state) do
    case state.type do
      "telnet" ->
        :gen_tcp.send(state.socket, iac)

      "secure telnet" ->
        :ssl.send(state.socket, iac)
    end

    case Keyword.has_key?(opts, :telemetry) do
      true ->
        metadata = Keyword.get(opts, :metadata, %{})
        metadata = maybe_add_game_to_metadata(state, metadata)

        :telemetry.execute([:telnet] ++ opts[:telemetry], %{count: 1}, metadata)

      false ->
        :ok
    end

    {:noreply, state}
  end

  def handle_info({:tcp, _port, data}, state) do
    process_data(data, state)
  end

  def handle_info({:ssl, _socket, data}, state) do
    process_data(data, state)
  end

  def handle_info({:tcp_closed, _port}, state) do
    state.module.disconnected(state)
    {:stop, :normal, state}
  end

  def handle_info({:ssl_closed, _socket}, state) do
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

  defp connect(state = %{type: "telnet"}) do
    host = String.to_charlist(state.host)
    :gen_tcp.connect(host, state.port, [:binary, {:packet, :raw}])
  end

  defp connect(state = %{type: "secure telnet"}) do
    host = String.to_charlist(state.host)
    opts = [:binary, {:cacerts, :certifi.cacerts()}, {:depth, 99}]

    case is_nil(state.certificate) do
      true ->
        :ssl.connect(host, state.port, [{:verify, :verify_peer} | opts])

      false ->
        :ssl.connect(host, state.port, [
          {:verify_fun, {&verify_cert/3, [state.certificate]}} | opts
        ])
    end
  end

  defp verify_cert(cert, {:bad_cert, :selfsigned_peer}, state = [pinned_cert]) do
    {_, _, _, cert_binary} = cert
    [{:Certificate, pinned_cert, :not_encrypted}] = :public_key.pem_decode(pinned_cert)
    pinned_cert = :public_key.der_decode(:Certificate, pinned_cert)

    case pinned_cert do
      {_, _, _, ^cert_binary} ->
        {:valid, state}

      _ ->
        {:fail, "invalid"}
    end
  end

  defp verify_cert(_cert, reason, _state) do
    {:fail, reason}
  end

  defp process_data(data, state) do
    {options, string, buffer} = Options.parse(state.buffer <> data)
    state = %{state | buffer: buffer}

    Enum.each(options, fn option ->
      send(self(), {:process, option})
    end)

    case String.valid?(String.last(string)) do
      true ->
        state.module.receive(state, string)

      false ->
        {:noreply, %{state | buffer: string <> state.buffer}}
    end
  end

  defp maybe_add_game_to_metadata(%{game: game}, metadata) when game != nil do
    Map.put(metadata, :game_id, game.id)
  end

  defp maybe_add_game_to_metadata(_state, metadata) do
    Map.put(metadata, :game_id, 0)
  end

  defp process_option(state, option = {:will, :mssp}) do
    socket_send(@do_mssp, telemetry: [:mssp, :sent])

    {:noreply, %{state | processed: [option | state.processed]}}
  end

  defp process_option(state, option = {:will, :gmcp}) do
    socket_send(<<255, 253, 201>>, telemetry: [:gmcp, :sent])
    hello = Jason.encode!(%{client: "Grapevine", version: GrapevineTelnet.version()})
    socket_send(<<255, 250, 201>> <> "Core.Hello #{hello}" <> <<255, 240>>, [])
    state = Features.enable_gmcp(state)

    supported_packages = Features.supported_packages(state)
    encoded_packages = Jason.encode!(supported_packages)
    socket_send(<<255, 250, 201>> <> "Core.Supports.Set #{encoded_packages}" <> <<255, 240>>, [])
    state = Features.packages(state, supported_packages)
    state = Features.cache_supported_messages(state)

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

  defp process_option(state, option = {:do, :new_environ}) do
    state.module.process_option(state, {:do, :new_environ})
    {:noreply, %{state | processed: [option | state.processed]}}
  end

  defp process_option(state, {:new_environ, :send, values}) do
    state.module.process_option(state, {:new_environ, :send, values})
    {:noreply, state}
  end

  defp process_option(state, option = {:do, :line_mode}) do
    socket_send(@wont_line_mode, telemetry: [:line_mode, :sent])
    {:noreply, %{state | processed: [option | state.processed]}}
  end

  defp process_option(state = %{type: "secure telnet"}, option = {:do, :oauth}) do
    socket_send(<<255, 251, 165>>, telemetry: [:oauth, :sent])
    params = %{host: "grapevine.haus"}

    socket_send(<<255, 250, 165>> <> "Start " <> Jason.encode!(params) <> <<255, 240>>,
      telemetry: [:oauth, :start]
    )

    {:noreply, %{state | processed: [option | state.processed]}}
  end

  # Not secure telnet, so we WONT do oauth
  defp process_option(state, option = {:do, :oauth}) do
    socket_send(<<255, 252, 165>>, telemetry: [:oauth, :sent])
    {:noreply, %{state | processed: [option | state.processed]}}
  end

  # Some clients will send a `DO GMCP`, we may have already responded to the WILL
  # let this fall into the void.
  defp process_option(state, option = {:do, :gmcp}) do
    {:noreply, %{state | processed: [option | state.processed]}}
  end

  defp process_option(state, {:charset, :request, sep, charsets}) do
    charsets =
      charsets
      |> String.split(sep)
      |> Enum.map(&String.downcase/1)

    case Enum.member?(charsets, "utf-8") do
      true ->
        socket_send(<<255, 250, 42, 2>> <> "UTF-8" <> <<255, 240>>,
          telemetry: [:charset, :accepted]
        )

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

    mtts = 1 + 4 + 8 + 128 + 256

    case state.term_type do
      :grapevine ->
        socket_send(start_term_type <> "Grapevine" <> end_term_type,
          telemetry: [:term_type, :details]
        )

        state = %{state | term_type: :ansi}
        {:noreply, state}

      :ansi ->
        socket_send(start_term_type <> "ANSI-TRUECOLOR" <> end_term_type,
          telemetry: [:term_type, :details]
        )

        state = %{state | term_type: :mtts}
        {:noreply, state}

      :mtts ->
        socket_send(start_term_type <> "MTTS #{mtts}" <> end_term_type,
          telemetry: [:term_type, :details]
        )

        {:noreply, state}
    end
  end

  defp process_option(state, option = {:gmcp, _, _}) do
    metadata = maybe_add_game_to_metadata(state, %{})
    :telemetry.execute([:telnet, :gmcp, :received], %{count: 1}, metadata)

    state.module.process_option(state, option)
  end

  defp process_option(state, option = {:oauth, _, _}) do
    state.module.process_option(state, option)
  end

  defp process_option(state, {:ga}) do
    state.module.process_option(state, {:ga})
  end

  defp process_option(state, {:wont, :echo}) do
    state.module.process_option(state, {:wont, :echo})
  end

  defp process_option(state, {:will, :echo}) do
    state.module.process_option(state, {:will, :echo})
  end

  defp process_option(state, {:will, option}) do
    byte = Options.option_to_byte(option)
    socket_send(<<255, 254, byte>>, telementry: [:wont], metadata: %{option: option})
    {:noreply, %{state | processed: [{:will, option} | state.processed]}}
  end

  defp process_option(state, {:do, option}) do
    byte = Options.option_to_byte(option)
    socket_send(<<255, 252, byte>>, telemetry: [:dont], metadata: %{option: option})
    {:noreply, %{state | processed: [{:do, option} | state.processed]}}
  end

  defp process_option(state, option) do
    state = %{state | processed: [option | state.processed]}
    state.module.process_option(state, option)
  end

  defp already_processed?(state, option) do
    Enum.member?(state.processed, option)
  end
end
