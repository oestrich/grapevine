defmodule GrapevineSocket.Metrics.Setup do
  @moduledoc false

  def setup do
    GrapevineSocket.Metrics.SocketInstrumenter.setup()
    GrapevineSocket.Metrics.PlugExporter.setup()
  end
end
