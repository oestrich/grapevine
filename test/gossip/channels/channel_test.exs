defmodule Gossip.Channels.ChannelTest do
  use Gossip.DataCase

  alias Gossip.Channels.Channel

  describe "validations on channel" do
    test "letters only" do
      changeset = %Channel{} |> Channel.changeset(%{name: "with a space"})
      assert changeset.errors[:name]
    end

    test "blocks certain names" do
      changeset = %Channel{} |> Channel.changeset(%{name: "all"})
      assert changeset.errors[:name]
    end

    test "shorter names" do
      changeset = %Channel{} |> Channel.changeset(%{name: "thisisalongerchannel"})
      assert changeset.errors[:name]
    end
  end
end
