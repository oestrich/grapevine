defmodule Metrics.Setup do
  @moduledoc """
  Common area to set up metrics
  """

  def setup() do
    Metrics.Events.ChannelsInstrumenter.setup()
    Metrics.Events.GamesInstrumenter.setup()
    Metrics.Events.PlayersInstrumenter.setup()
    Metrics.Events.TellsInstrumenter.setup()
    Metrics.GameInstrumenter.setup()
    Metrics.SocketInstrumenter.setup()
    Metrics.StatisticsInstrumenter.setup()

    Metrics.PlugExporter.setup()
  end
end
