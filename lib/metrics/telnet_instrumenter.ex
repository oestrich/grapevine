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
      [:failed],
      [:line_mode, :sent],
      [:option, :sent],
      [:option, :success],
      [:term_type, :sent],
      [:text, :sent],
      [:text, :success]
    ]

    events =
      Enum.map(events, fn event ->
        name = Enum.join(event, "_")

        Counter.declare(
          name: String.to_atom("gossip_telnet_mssp_#{name}_count"),
          help: "Total count of tracking for telnet MSSP event #{name}"
        )

        [:gossip, :telnet, :mssp | event]
      end)

    :telemetry.attach_many("gossip-telnet", events, &handle_event/4, nil)
  end

  def handle_event([:gossip, :telnet, :mssp, :start], _count, _metadata, _config) do
    Logger.debug("Starting MSSP", type: :mssp)
    Counter.inc(name: :gossip_telnet_mssp_start_count)
  end

  def handle_event([:gossip, :telnet, :mssp, :connected], _count, _metadata, _config) do
    Logger.debug("Connected to game", type: :mssp)
    Counter.inc(name: :gossip_telnet_mssp_connected_count)
  end

  def handle_event([:gossip, :telnet, :mssp, :failed], _count, state, _config) do
    Logger.debug(
      fn ->
        "Terminating connection to #{state.host}:#{state.port} due to no MSSP being sent"
      end,
      type: :mssp
    )

    Counter.inc(name: :gossip_telnet_mssp_failed_count)
  end

  def handle_event([:gossip, :telnet, :mssp, :option, :sent], _count, _metadata, _config) do
    Logger.debug("Sending telnet option", type: :mssp)
    Counter.inc(name: :gossip_telnet_mssp_option_sent_count)
  end

  def handle_event([:gossip, :telnet, :mssp, :option, :success], _count, state, _config) do
    Logger.info("Received MSSP from #{state.host}:#{state.port} - option version", type: :mssp)
    Counter.inc(name: :gossip_telnet_mssp_option_success_count)
  end

  def handle_event([:gossip, :telnet, :mssp, :line_mode, :sent], _count, _metadata, _config) do
    Logger.debug("Sending line mode", type: :mssp)
    Counter.inc(name: :gossip_telnet_mssp_line_mode_sent_count)
  end

  def handle_event([:gossip, :telnet, :mssp, :term_type, :sent], _count, _metadata, _config) do
    Logger.debug("Sending term type", type: :mssp)
    Counter.inc(name: :gossip_telnet_mssp_term_type_sent_count)
  end

  def handle_event([:gossip, :telnet, :mssp, :text, :sent], _count, _metadata, _config) do
    Logger.debug("Sending a text version of mssp request", type: :mssp)
    Counter.inc(name: :gossip_telnet_mssp_text_sent_count)
  end

  def handle_event([:gossip, :telnet, :mssp, :text, :success], _count, state, _config) do
    Logger.info("Received MSSP from #{state.host}:#{state.port} - text version", type: :mssp)
    Counter.inc(name: :gossip_telnet_mssp_text_success_count)
  end
end
