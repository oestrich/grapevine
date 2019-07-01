defmodule GrapevineData.ChannelsTest do
  use Grapevine.DataCase

  alias GrapevineData.Channels

  describe "creating a channel" do
    test "creates a new channel" do
      {:ok, channel} = Channels.create(%{name: "grapevine"})

      assert channel.name == "grapevine"
    end
  end
end
