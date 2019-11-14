defmodule Metrics.Setup do
  @moduledoc """
  Common area to set up metrics
  """

  @doc false
  def setup() do
    Metrics.AccountInstrumenter.setup()
    Metrics.Events.ChannelsInstrumenter.setup()
    Metrics.Events.GamesInstrumenter.setup()
    Metrics.Events.PlayersInstrumenter.setup()
    Metrics.Events.TellsInstrumenter.setup()
    Metrics.GameEventInstrumenter.setup()
    Metrics.GameInstrumenter.setup()
    Metrics.OAuthInstrumenter.setup()
    Metrics.StatisticsInstrumenter.setup()

    Metrics.PlugExporter.setup()
  end
end
