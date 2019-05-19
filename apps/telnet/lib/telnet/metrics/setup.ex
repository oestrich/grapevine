defmodule GrapevineTelnet.Metrics.Setup do
  @moduledoc """
  Set up all of the local metrics
  """

  @doc false
  def setup() do
    GrapevineTelnet.Metrics.ClientInstrumenter.setup()
    GrapevineTelnet.Metrics.PlugExporter.setup()
  end
end
