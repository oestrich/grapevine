defmodule Metrics.AccountInstrumenter do
  @moduledoc """
  Accounts instrumenter for Prometheus and Telemetry
  """

  use Prometheus.Metric

  require Logger

  @doc false
  def setup() do
    events = [
      [:create],
      [:session, :login],
      [:session, :logout]
    ]

    Enum.each(events, &setup_event/1)
  end

  defp setup_event(event) do
    name = Enum.join(event, "_")
    name = "grapevine_accounts_#{name}"

    Counter.declare(
      name: String.to_atom("#{name}_total"),
      help: "Total count of tracking for account event #{name}"
    )

    :telemetry.attach(name, [:grapevine, :accounts | event], &handle_event/4, nil)
  end

  def handle_event([:grapevine, :accounts, :create], _value, _metadata, _config) do
    Counter.inc(name: :grapevine_accounts_create_total)
  end

  def handle_event([:grapevine, :accounts, :session, :login], _value, _metadata, _config) do
    Counter.inc(name: :grapevine_accounts_session_login_total)
  end

  def handle_event([:grapevine, :accounts, :session, :logout], _value, _metadata, _config) do
    Counter.inc(name: :grapevine_accounts_session_logout_total)
  end
end
