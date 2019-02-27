defmodule Web.TimeView do
  @moduledoc """
  Time helper functions
  """

  def time(time) do
    timezone = Timex.Timezone.get("America/New_York", Timex.now())

    time
    |> Timex.Timezone.convert(timezone)
    |> Timex.format!("%Y-%m-%d %I:%M %p", :strftime)
  end

  def relative(time) do
    Timex.format!(time, "{relative}", :relative)
  end
end
