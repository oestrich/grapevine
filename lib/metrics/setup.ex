defmodule Metrics.Setup do
  @moduledoc """
  Common area to set up metrics
  """

  def setup() do
    Metrics.ChannelsInstrumenter.setup()
    Metrics.GameInstrumenter.setup()
    Metrics.SocketInstrumenter.setup()

    Metrics.PlugExporter.setup()
  end
end
