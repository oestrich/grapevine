defmodule Grapevine.ChannelsTest do
  use Grapevine.DataCase

  alias Grapevine.Channels

  describe "creating a channel" do
    test "creates a new channel" do
      {:ok, channel} = Channels.create(%{name: "grapevine"})

      assert channel.name == "grapevine"
    end
  end
end
