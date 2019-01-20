defmodule Metrics.Setup do
  @moduledoc """
  Common area to set up metrics
  """

  @doc false
  def setup() do
    Metrics.Events.ChannelsInstrumenter.setup()
    Metrics.Events.GamesInstrumenter.setup()
    Metrics.Events.PlayersInstrumenter.setup()
    Metrics.Events.TellsInstrumenter.setup()
    Metrics.GameEventInstrumenter.setup()
    Metrics.GameInstrumenter.setup()
    Metrics.OAuthInstrumenter.setup()
    Metrics.SocketInstrumenter.setup()
    Metrics.StatisticsInstrumenter.setup()
    Metrics.TelnetInstrumenter.setup()

    Metrics.PlugExporter.setup()
  end
end
