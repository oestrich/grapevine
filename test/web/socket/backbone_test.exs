defmodule Web.Socket.BackboneTest do
  use Gossip.DataCase

  alias Gossip.Channels.Channel
  alias Web.Socket.Backbone

  describe "backbone processing" do
    setup do
      application = create_application()
      state = %{status: "active", game: application}

      %{state: state, application: application}
    end

    test "new channel subscribes to that new channel", %{state: state} do
      message = %Phoenix.Socket.Broadcast{topic: "system:backbone", event: "channels/new", payload: %Channel{name: "newChannel"}}
      Backbone.process_event(state, message)

      Web.Endpoint.broadcast("channels:newChannel", "channels/broadcast", %{message: "hi"})

      assert_receive %{event: "channels/broadcast", payload: %{message: "hi"}}
    end
  end

  describe "syncing channels" do
    test "sends channel notices over the backbone" do
      Web.Endpoint.subscribe("system:backbone")

      create_channel(%{name: "gossip"})

      Backbone.sync_channels()

      assert_receive %{event: "sync/channels"}
    end

    test "batches into groups of 10" do
      Web.Endpoint.subscribe("system:backbone")

      Enum.each(1..12, fn i ->
        create_channel(%{name: "gossip#{[?a + i]}"})
      end)

      Backbone.sync_channels()

      assert_receive %{event: "sync/channels"}
      assert_receive %{event: "sync/channels"}
    end
  end
end
