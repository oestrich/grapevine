defmodule Web.GameStatisticView do
  use Web, :view

  alias Web.GameView

  def render("players.json", %{statistics: statistics}) do
    statistics =
      Enum.map(statistics, fn {time, count} ->
        %{time: Timex.to_datetime(time), count: count}
      end)

    %{statistics: statistics}
  end

  def render("players-tod.json", %{statistics: statistics}) do
    statistics =
      Enum.map(statistics, fn {hour, count} ->
        %{hour: hour, count: count}
      end)

    %{statistics: statistics}
  end
end
