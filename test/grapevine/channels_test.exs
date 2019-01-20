defmodule Grapevine.ChannelsTest do
  use Grapevine.DataCase

  alias Grapevine.Channels

  describe "creating a channel" do
    test "creates a new channel" do
      {:ok, channel} = Channels.create(%{name: "grapevine"})

      assert channel.name == "grapevine"
    end

    test "sends a notification about a new channel" do
      Web.Endpoint.subscribe("system:backbone")

      {:ok, _channel} = Channels.create(%{name: "grapevine"})

      assert_receive %Phoenix.Socket.Broadcast{topic: "system:backbone", event: "channels/new"}
    end
  end
end
