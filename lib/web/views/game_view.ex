defmodule Web.GameView do
  use Web, :view

  alias Gossip.Channels

  def channel_checked?(game, channel) do
    subscribed? =
      game.subscribed_channels
      |> Enum.map(&(&1.channel_id))
      |> Enum.member?(channel.id)

    case subscribed? do
      true ->
        "checked"

      false ->
        ""
    end
  end
end
