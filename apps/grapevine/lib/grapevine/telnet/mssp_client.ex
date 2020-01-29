defmodule Grapevine.Telnet.MSSPClient do
  @moduledoc """
  Callbacks for specifically checking MSSP data
  """

  require Logger

  alias Grapevine.Telnet.MSSPClient.Check
  alias Grapevine.Telnet.MSSPClient.Record
  alias GrapevineTelnet.Client
  alias Telnet.MSSP

  @behaviour Client

  def start_link(opts) do
    Client.start_link(__MODULE__, opts)
  end

  @impl true
  def init(state, opts) do
    Process.send_after(self(), {:text_mssp_request}, 10_000)
    Process.send_after(self(), {:stop}, 20_000)
    generate_state(state, opts)
  end

  defp generate_state(state, opts) do
    case opts[:type] do
      :check ->
        Check.init(opts, state)

      :record ->
        Record.init(opts, state)
    end
  end

  @impl true
  def connected(state) do
    state.mssp_module.connected(state)
  end

  @impl true
  def connection_failed(state, _error) do
    state.mssp_module.connection_failed(state)
  end

  @impl true
  def disconnected(_state), do: :ok

  @impl true
  def process_option(state, {:mssp, data}) do
    maybe_forward("mssp/received", data, state)
    state.mssp_module.record_option(state, data)
    :telemetry.execute([:telnet, :mssp, :option, :success], %{count: 1}, state)

    Logger.debug("Shutting down MSSP check", type: :mssp)

    {:stop, :normal, state}
  end

  def process_option(state, _option), do: {:noreply, state}

  @impl true
  def receive(state, data) do
    state = Map.put(state, :mssp_buffer, Map.get(state, :mssp_buffer, "") <> data)

    case text_mssp?(state.mssp_buffer) do
      true ->
        record_text_mssp(state)

      false ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:text_mssp_request}, state) do
    :gen_tcp.send(state.socket, "mssp-request\n")
    :telemetry.execute([:telnet, :mssp, :text, :sent], %{count: 1}, state)

    {:noreply, Map.put(state, :mssp_buffer, <<>>)}
  end

  def handle_info({:stop}, state) do
    maybe_forward("mssp/terminated", %{}, state)
    state.mssp_module.record_fail(state)

    GrapevineData.Telnet.record_no_mssp(state.host, state.port)
    :telemetry.execute([:telnet, :mssp, :failed], %{count: 1}, state)

    {:stop, :normal, state}
  end

  @doc """
  Record MSSP data sent via plain text
  """
  def record_text_mssp(state) do
    case MSSP.parse_text(state.mssp_buffer) do
      :error ->
        {:noreply, state}

      data ->
        maybe_forward("mssp/received", data, state)
        state.mssp_module.record_text(state, data)
        :telemetry.execute([:telnet, :mssp, :text, :success], %{count: 1}, state)

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

  def text_mssp?(string) do
    string =~ "MSSP-REPLY-START"
  end

  defmodule Record do
    @moduledoc """
    Record player counts from MSSP
    """

    alias Grapevine.Games
    alias GrapevineData.Statistics

    def init(opts, state) do
      connection = Keyword.get(opts, :connection)

      state
      |> Map.put(:mssp_module, __MODULE__)
      |> Map.put(:connection, connection)
      |> Map.put(:type, connection.type)
      |> Map.put(:game, %{connection.game | gauges: []})
      |> Map.put(:host, connection.host)
      |> Map.put(:port, connection.port)
    end

    def connected(state) do
      Games.seen_on_telnet(state.game)
      Games.connection_succeeded(state.connection)
    end

    def connection_failed(state) do
      Games.connection_failed(state.connection)
    end

    def record_option(state, data) do
      Games.connection_has_mssp(state.connection)
      maybe_set_user_agent(state, data)

      players = String.to_integer(Map.get(data, "PLAYERS", "0"))
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

    alias GrapevineData.Telnet

    def init(opts, state) do
      state
      |> Map.put(:mssp_module, __MODULE__)
      |> Map.put(:type, "telnet")
      |> Map.put(:host, Keyword.get(opts, :host))
      |> Map.put(:port, Keyword.get(opts, :port))
      |> Map.put(:channel, Keyword.get(opts, :channel))
    end

    def connected(_state), do: :ok

    def connection_failed(_state), do: :ok

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
end
