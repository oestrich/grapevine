defmodule Web.GameStatisticView do
  use Web, :view

  def render("players.json", %{statistics: statistics}) do
    statistics =
      Enum.map(statistics, fn {time, count} ->
        %{time: Timex.to_datetime(time), count: count}
      end)

    %{statistics: statistics}
  end
end
