defmodule Gossip.ChannelsTest do
  use Gossip.DataCase

  alias Gossip.Channels

  describe "subscribing to channels" do
    setup do
      user = create_user()
      game = create_game(user)
      channel = create_channel()

      user = %{user | games: [game]}

      %{user: user, game: game, channel: channel}
    end

    test "creates subscribed channels", %{user: user, game: game, channel: channel} do
      {:ok, game} = Channels.subscribe_to_channels(user, game.id, [channel.id])

      assert length(game.subscribed_channels) == 1
    end

    test "removes old subscribed channels", %{user: user, game: game, channel: channel} do
      {:ok, game} = Channels.subscribe_to_channels(user, game.id, [channel.id])
      {:ok, game} = Channels.subscribe_to_channels(user, game.id, [])

      assert length(game.subscribed_channels) == 0
    end

    test "subscribes and removes all in one go", %{user: user, game: game, channel: channel} do
      new_channel = create_channel(%{name: "general"})

      {:ok, game} = Channels.subscribe_to_channels(user, game.id, [channel.id])
      {:ok, game} = Channels.subscribe_to_channels(user, game.id, [new_channel.id])

      assert length(game.subscribed_channels) == 1
    end

    test "game id not found", %{user: user, channel: channel} do
      assert :error = Channels.subscribe_to_channels(user, "-1", [channel.id])
    end
  end
end
