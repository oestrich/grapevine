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

  def handle_event([:grapevine, :telnet, :start], _count, _metadata, _config) do
    Logger.debug("Starting MSSP", type: :mssp)
    Counter.inc(name: :grapevine_telnet_start_count)
  end

  def handle_event([:grapevine, :telnet, :connected], _count, _metadata, _config) do
    Logger.debug("Connected to game", type: :mssp)
    Counter.inc(name: :grapevine_telnet_connected_count)
  end

  def handle_event([:grapevine, :telnet, :mssp, :sent], _count, _metadata, _config) do
    Logger.debug("Sending telnet option", type: :mssp)
    Counter.inc(name: :grapevine_telnet_mssp_sent_count)
  end

  def handle_event([:grapevine, :telnet, :line_mode, :sent], _count, _metadata, _config) do
    Logger.debug("Sending line mode", type: :mssp)
    Counter.inc(name: :grapevine_telnet_line_mode_sent_count)
  end

  def handle_event([:grapevine, :telnet, :term_type, :sent], _count, _metadata, _config) do
    Logger.debug("Sending term type", type: :mssp)
    Counter.inc(name: :grapevine_telnet_term_type_sent_count)
  end

  def handle_event([:grapevine, :telnet, :mssp, :option, :success], _count, state, _config) do
    Logger.info("Received MSSP from #{state.host}:#{state.port} - option version", type: :mssp)
    Counter.inc(name: :grapevine_telnet_mssp_option_success_count)
  end

  def handle_event([:grapevine, :telnet, :mssp, :text, :sent], _count, _metadata, _config) do
    Logger.debug("Sending a text version of mssp request", type: :mssp)
    Counter.inc(name: :grapevine_telnet_mssp_text_sent_count)
  end

  def handle_event([:grapevine, :telnet, :mssp, :text, :success], _count, state, _config) do
    Logger.info("Received MSSP from #{state.host}:#{state.port} - text version", type: :mssp)
    Counter.inc(name: :grapevine_telnet_mssp_text_success_count)
  end

  def handle_event([:grapevine, :telnet, :mssp, :failed], _count, state, _config) do
    Logger.debug(
      fn ->
        "Terminating connection to #{state.host}:#{state.port} due to no MSSP being sent"
      end,
      type: :mssp
    )

    Counter.inc(name: :grapevine_telnet_mssp_failed_count)
  end
end
