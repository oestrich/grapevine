defmodule GrapevineTelnet.Metrics.ClientInstrumenter do
  @moduledoc """
  Instrumentation for the telnet client
  """

  use Prometheus.Metric

  require Logger

  alias GrapevineTelnet.Presence

  @doc false
  def setup() do
    events = [
      [:start],
      [:connection, :connected],
      [:connection, :failed],
      [:wont],
      [:dont],
      [:charset, :sent],
      [:charset, :accepted],
      [:charset, :rejected],
      {[:gmcp, :sent], [:game_id]},
      {[:gmcp, :received], [:game_id]},
      [:line_mode, :sent],
      [:mssp, :failed],
      [:mssp, :option, :success],
      [:mssp, :sent],
      [:mssp, :text, :sent],
      [:mssp, :text, :success],
      [:term_type, :sent],
      [:term_type, :details]
    ]

    Enum.each(events, &setup_event/1)

    setup_gauges()
  end

  defp setup_event({event, labels}) do
    name = Enum.join(event, "_")
    name = "telnet_#{name}"

    Counter.declare(
      name: String.to_atom("#{name}_total"),
      help: "Total count of tracking for telnet event #{name}",
      labels: labels
    )

    :telemetry.attach(name, [:telnet | event], &handle_event/4, nil)
  end

  defp setup_event(event) do
    name = Enum.join(event, "_")
    name = "telnet_#{name}"

    Counter.declare(
      name: String.to_atom("#{name}_total"),
      help: "Total count of tracking for telnet event #{name}"
    )

    :telemetry.attach(name, [:telnet | event], &handle_event/4, nil)
  end

  defp setup_gauges() do
    Gauge.declare(
      name: :telnet_client_count,
      help: "Number of live web clients"
    )

    :telemetry.attach(
      "grapevine-client-online",
      [:telnet, :clients, :online],
      &handle_event/4,
      nil
    )
  end

  @doc """
  Dispatch a clients online telemetry execute

  Called from the telemetry-poller
  """
  def dispatch_client_count() do
    :telemetry.execute(
      [:telnet, :clients, :online],
      %{count: Presence.online_client_count()},
      %{}
    )
  end

  def handle_event([:telnet, :clients, :online], %{count: count}, _metadata, _config) do
    Gauge.set([name: :telnet_client_count], count)
  end

  def handle_event([:telnet, :start], _count, %{host: host, port: port}, _config) do
    Logger.debug(
      fn ->
        "Starting Telnet Client: #{host}:#{port}"
      end,
      type: :telnet
    )

    Counter.inc(name: :telnet_start_total)
  end

  def handle_event([:telnet, :connection, :connected], _count, _metadata, _config) do
    Logger.debug("Connected to game", type: :telnet)
    Counter.inc(name: :telnet_connection_connected_total)
  end

  def handle_event([:telnet, :connection, :failed], _count, metadata, _config) do
    Logger.debug(
      fn ->
        "Could not connect to a game - #{inspect(metadata[:error])}"
      end,
      type: :telnet
    )

    Counter.inc(name: :telnet_connection_failed_total)
  end

  def handle_event([:telnet, :wont], _count, metadata, _config) do
    Logger.debug(
      fn ->
        "Rejecting a WONT #{metadata[:byte]}"
      end,
      type: :telnet
    )

    Counter.inc(name: :telnet_wont_total)
  end

  def handle_event([:telnet, :dont], _count, metadata, _config) do
    Logger.debug(
      fn ->
        "Rejecting a DO #{metadata[:byte]}"
      end,
      type: :telnet
    )

    Counter.inc(name: :telnet_dont_total)
  end

  def handle_event([:telnet, :charset, :sent], _count, _metadata, _config) do
    Logger.debug("Responding to CHARSET", type: :telnet)
    Counter.inc(name: :telnet_charset_sent_total)
  end

  def handle_event([:telnet, :charset, :accepted], _count, _metadata, _config) do
    Logger.debug("Accepting charset", type: :telnet)
    Counter.inc(name: :telnet_charset_accepted_total)
  end

  def handle_event([:telnet, :charset, :rejected], _count, _metadata, _config) do
    Logger.debug("Rejecting charset", type: :telnet)
    Counter.inc(name: :telnet_charset_rejected_total)
  end

  def handle_event([:telnet, :gmcp, :sent], _count, metadata, _config) do
    Logger.debug("Responding to GMCP", type: :telnet)
    Counter.inc(name: :telnet_gmcp_sent_total, labels: [metadata[:game_id]])
  end

  def handle_event([:telnet, :gmcp, :received], _count, metadata, _config) do
    Logger.debug("Received GMCP Message", type: :telnet)
    Counter.inc(name: :telnet_gmcp_received_total, labels: [metadata[:game_id]])
  end

  def handle_event([:telnet, :mssp, :sent], _count, _metadata, _config) do
    Logger.debug("Sending MSSP via telnet option", type: :telnet)
    Counter.inc(name: :telnet_mssp_sent_total)
  end

  def handle_event([:telnet, :line_mode, :sent], _count, _metadata, _config) do
    Logger.debug("Responding to LINEMODE", type: :telnet)
    Counter.inc(name: :telnet_line_mode_sent_total)
  end

  def handle_event([:telnet, :term_type, :sent], _count, _metadata, _config) do
    Logger.debug("Responding to TTYPE", type: :telnet)
    Counter.inc(name: :telnet_term_type_sent_total)
  end

  def handle_event([:telnet, :term_type, :details], _count, _metadata, _config) do
    Logger.debug("Responding to TTYPE request", type: :telnet)
  end

  def handle_event([:telnet, :mssp, :option, :success], _count, state, _config) do
    Logger.info("Received MSSP from #{state.host}:#{state.port} - option version", type: :telnet)
    Counter.inc(name: :telnet_mssp_option_success_total)
  end

  def handle_event([:telnet, :mssp, :text, :sent], _count, _metadata, _config) do
    Logger.debug("Sending a text version of mssp request", type: :telnet)
    Counter.inc(name: :telnet_mssp_text_sent_total)
  end

  def handle_event([:telnet, :mssp, :text, :success], _count, state, _config) do
    Logger.info("Received MSSP from #{state.host}:#{state.port} - text version", type: :telnet)
    Counter.inc(name: :telnet_mssp_text_success_total)
  end

  def handle_event([:telnet, :mssp, :failed], _count, state, _config) do
    Logger.debug(
      fn ->
        "Terminating connection to #{state.host}:#{state.port} due to no MSSP being sent"
      end,
      type: :telnet
    )

    Counter.inc(name: :telnet_mssp_failed_total)
  end
end
