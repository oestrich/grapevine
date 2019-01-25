defmodule Grapevine.Telnet.Client do
  @moduledoc """
  A client to check for MSSP data
  """

  use GenServer

  require Logger

  @do_mssp <<255, 253, 70>>
  @will_term_type <<255, 251, 24>>
  @term_type <<255, 250, 24, 0>> <> "Grapevine" <> <<255, 240>>
  @wont_line_mode <<255, 252, 34>>

  alias Grapevine.Telnet
  alias Grapevine.Telnet.MSSP
  alias Grapevine.Telnet.Options

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  defp send_do_mssp() do
    GenServer.cast(self(), {:send_do_mssp})
  end

  defp send_term_type() do
    GenServer.cast(self(), {:send_term_type})
  end

  defp send_line_mode() do
    GenServer.cast(self(), {:send_line_mode})
  end

  def init(opts) do
    Process.send_after(self(), {:text_mssp_request}, 10_000)
    Process.send_after(self(), {:stop}, 20_000)

    state = generate_state(opts)

    :telemetry.execute([:grapevine, :telnet, :mssp, :start], 1, state)

    {:ok, state, {:continue, :connect}}
  end

  def handle_continue(:connect, state) do
    host = String.to_charlist(state.host)
    {:ok, socket} = :gen_tcp.connect(host, state.port, [:binary, {:packet, 0}])
    :telemetry.execute([:grapevine, :telnet, :mssp, :connected], 1, state)
    {:noreply, Map.put(state, :socket, socket)}
  end

  def handle_cast({:send_do_mssp}, state) do
    :gen_tcp.send(state.socket, @do_mssp)
    :telemetry.execute([:grapevine, :telnet, :mssp, :option, :sent], 1, state)
    {:noreply, state}
  end

  def handle_cast({:send_term_type}, state) do
    :gen_tcp.send(state.socket, @will_term_type)
    :gen_tcp.send(state.socket, @term_type)
    :telemetry.execute([:grapevine, :telnet, :mssp, :term_type, :sent], 1, state)
    {:noreply, state}
  end

  def handle_cast({:send_line_mode}, state) do
    :gen_tcp.send(state.socket, @wont_line_mode)
    :telemetry.execute([:grapevine, :telnet, :mssp, :line_mode, :sent], 1, state)
    {:noreply, state}
  end

  def handle_info({:text_mssp_request}, state) do
    :gen_tcp.send(state.socket, "mssp-request\n")
    :telemetry.execute([:grapevine, :telnet, :mssp, :text, :sent], 1, state)

    {:noreply, %{state | data: <<>>}}
  end

  def handle_info({:stop}, state) do
    maybe_forward("mssp/terminated", %{}, state)
    Telnet.record_no_mssp(state.host, state.port)
    :telemetry.execute([:grapevine, :telnet, :mssp, :failed], 1, state)

    state.module.record_fail(state)

    {:stop, :normal, state}
  end

  def handle_info({:tcp, _port, data}, state) do
    state = %{state | data: state.data <> data}
    options = Options.parse(state.data)

    Enum.each(options, fn option ->
      send(self(), {:process, option})
    end)

    cond do
      Options.mssp_data?(options) ->
        record_option_mssp(options, state, fn data ->
          state.module.record_option(state, data)
        end)

      Options.text_mssp?(state.data) ->
        record_text_mssp(state, fn data ->
          state.module.record_text(state, data)
        end)

      true ->
        {:noreply, state}
    end
  end

  def handle_info({:process, option}, state) do
    cond do
      already_processed?(state, option) ->
        {:noreply, state}

      Options.will_mssp?(option) ->
        send_do_mssp()
        {:noreply, %{state | processed: [option | state.processed]}}

      Options.do_term?(option) ->
        send_term_type()
        {:noreply, %{state | processed: [option | state.processed]}}

      Options.do_line_mode?(option) ->
        send_line_mode()
        {:noreply, %{state | processed: [option | state.processed]}}

      true ->
        {:noreply, %{state | processed: [option | state.processed]}}
    end
  end

  defp already_processed?(state, option) do
    Enum.member?(state.processed, option)
  end

  defmodule Record do
    @moduledoc """
    Record player counts from MSSP
    """

    alias Grapevine.Games
    alias Grapevine.Statistics

    def init(opts, state) do
      connection = Keyword.get(opts, :connection)

      state
      |> Map.put(:module, Grapevine.Telnet.Client.Record)
      |> Map.put(:connection, connection)
      |> Map.put(:game, connection.game)
      |> Map.put(:host, connection.host)
      |> Map.put(:port, connection.port)
    end

    def record_option(state, data) do
      Games.seen_on_mssp(state.game)
      Games.connection_has_mssp(state.connection)
      maybe_set_user_agent(state, data)

      players = String.to_integer(data["PLAYERS"])
      Statistics.record_mssp_players(state.game, players, Timex.now())
    end

    def record_text(state, data) do
      record_option(state, data)
    end

    def record_fail(state) do
      Games.connection_has_no_mssp(state.connection)
    end

    defp maybe_set_user_agent(state, data) do
      case Map.get(data, "CODEBASE") do
        nil ->
          :ok

        codebase ->
          Games.record_metadata(state.game, %{user_agent: codebase})
      end
    end
  end

  defmodule Check do
    @moduledoc """
    Check MSSP for a game
    """

    alias Grapevine.Telnet

    def init(opts, state) do
      state
      |> Map.put(:module, Grapevine.Telnet.Client.Check)
      |> Map.put(:host, Keyword.get(opts, :host))
      |> Map.put(:port, Keyword.get(opts, :port))
      |> Map.put(:channel, Keyword.get(opts, :channel))
    end

    def record_option(state, data) do
      Telnet.record_mssp_response(state.host, state.port, data)
    end

    def record_text(state, data) do
      Telnet.record_mssp_response(state.host, state.port, data)
    end

    def record_fail(_state) do
      :ok
    end
  end

  defp generate_state(opts) do
    state = %{data: <<>>, processed: []}

    case opts[:type] do
      :check ->
        Grapevine.Telnet.Client.Check.init(opts, state)

      :record ->
        Grapevine.Telnet.Client.Record.init(opts, state)
    end
  end

  def record_option_mssp(options, state, fun) do
    {:mssp, data} = Options.get_mssp_data(options)
    maybe_forward("mssp/received", data, state)
    fun.(data)
    :telemetry.execute([:grapevine, :telnet, :mssp, :option, :success], 1, state)

    {:stop, :normal, state}
  end

  def record_text_mssp(state, fun) do
    case MSSP.parse_text(state.data) do
      :error ->
        {:noreply, state}

      data ->
        maybe_forward("mssp/received", data, state)
        fun.(data)
        :telemetry.execute([:grapevine, :telnet, :mssp, :text, :success], 1, state)

        {:stop, :normal, state}
    end
  end

  defp maybe_forward(event, message, state) do
    case Map.get(state, :channel) do
      nil ->
        :ok

      channel ->
        Web.Endpoint.broadcast("mssp:#{channel}", event, message)
    end
  end
end
