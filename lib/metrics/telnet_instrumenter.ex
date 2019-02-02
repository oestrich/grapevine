defmodule Metrics.TelnetInstrumenter do
  @moduledoc """
  Instrumentation for the telnet client
  """

  use Prometheus.Metric

  require Logger

  @doc false
  def setup() do
    events = [
      [:start],
      [:connected],
      [:wont],
      [:dont],
      [:charset, :sent],
      [:charset, :accepted],
      [:charset, :rejected],
      [:line_mode, :sent],
      [:mssp, :sent],
      [:term_type, :sent],

      # mssp specific
      [:mssp, :failed],
      [:mssp, :option, :success],
      [:mssp, :text, :sent],
      [:mssp, :text, :success]
    ]

    events =
      Enum.map(events, fn event ->
        name = Enum.join(event, "_")

        Counter.declare(
          name: String.to_atom("grapevine_telnet_#{name}_count"),
          help: "Total count of tracking for telnet MSSP event #{name}"
        )

        [:grapevine, :telnet | event]
      end)

    :telemetry.attach_many("grapevine-telnet", events, &handle_event/4, nil)
  end

  def handle_event([:grapevine, :telnet, :start], _count, %{host: host, port: port}, _config) do
    Logger.debug(fn ->
      "Starting Telnet Client: #{host}:#{port}"
    end, type: :telnet)
    Counter.inc(name: :grapevine_telnet_start_count)
  end

  def handle_event([:grapevine, :telnet, :connected], _count, _metadata, _config) do
    Logger.debug("Connected to game", type: :telnet)
    Counter.inc(name: :grapevine_telnet_connected_count)
  end

  def handle_event([:grapevine, :telnet, :wont], _count, _metadata, _config) do
    Logger.debug("Rejecting a WONT", type: :telnet)
  end

  def handle_event([:grapevine, :telnet, :dont], _count, _metadata, _config) do
    Logger.debug("Rejecting a DO", type: :telnet)
  end

  def handle_event([:grapevine, :telnet, :charset, :sent], _count, _metadata, _config) do
    Logger.debug("Sending charset", type: :telnet)
  end

  def handle_event([:grapevine, :telnet, :charset, :accepted], _count, _metadata, _config) do
    Logger.debug("Accepting charset", type: :telnet)
  end

  def handle_event([:grapevine, :telnet, :charset, :rejected], _count, _metadata, _config) do
    Logger.debug("Rejecting charset", type: :telnet)
  end

  def handle_event([:grapevine, :telnet, :mssp, :sent], _count, _metadata, _config) do
    Logger.debug("Sending telnet option", type: :telnet)
    Counter.inc(name: :grapevine_telnet_mssp_sent_count)
  end

  def handle_event([:grapevine, :telnet, :line_mode, :sent], _count, _metadata, _config) do
    Logger.debug("Sending line mode", type: :telnet)
    Counter.inc(name: :grapevine_telnet_line_mode_sent_count)
  end

  def handle_event([:grapevine, :telnet, :term_type, :sent], _count, _metadata, _config) do
    Logger.debug("Sending term type", type: :telnet)
    Counter.inc(name: :grapevine_telnet_term_type_sent_count)
  end

  def handle_event([:grapevine, :telnet, :mssp, :option, :success], _count, state, _config) do
    Logger.info("Received MSSP from #{state.host}:#{state.port} - option version", type: :telnet)
    Counter.inc(name: :grapevine_telnet_mssp_option_success_count)
  end

  def handle_event([:grapevine, :telnet, :mssp, :text, :sent], _count, _metadata, _config) do
    Logger.debug("Sending a text version of mssp request", type: :telnet)
    Counter.inc(name: :grapevine_telnet_mssp_text_sent_count)
  end

  def handle_event([:grapevine, :telnet, :mssp, :text, :success], _count, state, _config) do
    Logger.info("Received MSSP from #{state.host}:#{state.port} - text version", type: :telnet)
    Counter.inc(name: :grapevine_telnet_mssp_text_success_count)
  end

  def handle_event([:grapevine, :telnet, :mssp, :failed], _count, state, _config) do
    Logger.debug(
      fn ->
        "Terminating connection to #{state.host}:#{state.port} due to no MSSP being sent"
      end,
      type: :telnet
    )

    Counter.inc(name: :grapevine_telnet_mssp_failed_count)
  end
end
