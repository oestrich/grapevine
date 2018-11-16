defmodule Web.GameStatisticView do
  use Web, :view

  def render("players.json", %{statistics: statistics}) do
    Enum.into(statistics, %{})
  end
end
