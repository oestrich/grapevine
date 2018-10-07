defmodule Gossip.ChannelsTest do
  use Gossip.DataCase

  alias Gossip.Channels

  describe "creating a channel" do
    test "creates a new channel" do
      {:ok, channel} = Channels.create(%{name: "gossip"})

      assert channel.name == "gossip"
    end

    test "sends a notification about a new channel" do
      Web.Endpoint.subscribe("system:backbone")

      {:ok, _channel} = Channels.create(%{name: "gossip"})

      assert_receive %Phoenix.Socket.Broadcast{topic: "system:backbone", event: "channels/new"}
    end
  end
end
