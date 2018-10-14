defmodule Web.Socket.BackboneTest do
  use Gossip.DataCase

  alias Gossip.Channels.Channel
  alias Gossip.Games.Game
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

    test "broadcasts new games", %{state: state} do
      message = %Phoenix.Socket.Broadcast{
        topic: "system:backbone",
        event: "games/new",
        payload: %Game{name: "game", connections: []}
      }

      Backbone.process_event(state, message)

      assert_receive {:broadcast, %{event: "sync/games"}}
    end

    test "broadcasts edited games", %{state: state} do
      message = %Phoenix.Socket.Broadcast{
        topic: "system:backbone",
        event: "games/edit",
        payload: %Game{name: "game", connections: []}
      }

      Backbone.process_event(state, message)

      assert_receive {:broadcast, %{event: "sync/games"}}
    end
  end

  describe "syncing channels" do
    test "sends channel notices over the backbone" do
      create_channel(%{name: "gossip"})

      Backbone.sync_channels()

      assert_receive {:broadcast, %{event: "sync/channels"}}
    end

    test "batches into groups of 10" do
      Enum.each(1..12, fn i ->
        create_channel(%{name: "gossip#{[?a + i]}"})
      end)

      Backbone.sync_channels()

      assert_receive {:broadcast, %{event: "sync/channels"}}
      assert_receive {:broadcast, %{event: "sync/channels"}}
    end
  end

  describe "syncing games" do
    test "sends game notices over the backbone" do
      user = create_user()
      create_game(user)

      Backbone.sync_games()

      assert_receive {:broadcast, %{event: "sync/games"}}
    end

    test "batches into groups of 10" do
      user = create_user()
      Enum.each(1..12, fn i ->
        create_game(user, %{
          name: "gossip#{[?a + i]}",
          short_name: "gossip#{[?a + i]}",
        })
      end)

      Backbone.sync_games()

      assert_receive {:broadcast, %{event: "sync/games"}}
      assert_receive {:broadcast, %{event: "sync/games"}}
    end
  end
end
