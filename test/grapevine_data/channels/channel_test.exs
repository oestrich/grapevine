defmodule GrapevineData.Channels.ChannelTest do
  use Grapevine.DataCase

  alias GrapevineData.Channels.Channel

  describe "validations on channel" do
    test "letters only" do
      changeset = %Channel{} |> Channel.changeset(%{name: "with a space"})
      assert changeset.errors[:name]
    end

    test "allows dashes" do
      changeset = %Channel{} |> Channel.changeset(%{name: "with-a-dash"})
      refute changeset.errors[:name]
    end

    test "allows underscores" do
      changeset = %Channel{} |> Channel.changeset(%{name: "with_underscore"})
      refute changeset.errors[:name]
    end

    test "blocks certain names" do
      changeset = %Channel{} |> Channel.changeset(%{name: "all"})
      assert changeset.errors[:name]
    end

    test "shorter names" do
      changeset = %Channel{} |> Channel.changeset(%{name: "thisisalongerchannel"})
      assert changeset.errors[:name]
    end

    test "not long enough" do
      changeset = %Channel{} |> Channel.changeset(%{name: "a"})
      assert changeset.errors[:name]
    end
  end
end
