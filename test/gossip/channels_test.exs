defmodule Gossip.ChannelsTest do
  use Gossip.DataCase

  alias Gossip.Channels

  describe "subscribing to channels" do
    setup do
      game = create_game()
      channel = create_channel()

      %{game: game, channel: channel}
    end

    test "creates subscribed channels", %{game: game, channel: channel} do
      {:ok, game} = Channels.subscribe_to_channels(game, [channel.id])

      assert length(game.subscribed_channels) == 1
    end

    test "removes old subscribed channels", %{game: game, channel: channel} do
      {:ok, game} = Channels.subscribe_to_channels(game, [channel.id])
      {:ok, game} = Channels.subscribe_to_channels(game, [])

      assert length(game.subscribed_channels) == 0
    end

    test "subscribes and removes all in one go", %{game: game, channel: channel} do
      new_channel = create_channel(%{name: "general"})

      {:ok, game} = Channels.subscribe_to_channels(game, [channel.id])
      {:ok, game} = Channels.subscribe_to_channels(game, [new_channel.id])

      assert length(game.subscribed_channels) == 1
    end
  end
end
