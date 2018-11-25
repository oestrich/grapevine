defmodule Socket.BackboneTest do
  use Gossip.DataCase

  alias Gossip.Games
  alias Gossip.Versions
  alias Gossip.Versions.Version
  alias Socket.Backbone

  describe "backbone processing" do
    setup do
      application = create_application()
      state = %{status: "active", game: application}

      %{state: state, application: application}
    end

    test "new channel subscribes to that new channel", %{state: state} do
      payload = %Version{action: "create", payload: %{name: "newChannel"}}

      message = %Phoenix.Socket.Broadcast{topic: "system:backbone", event: "channels/new", payload: payload}
      Backbone.process_event(state, message)

      Web.Endpoint.broadcast("channels:newChannel", "channels/broadcast", %{message: "hi"})

      assert_receive %{event: "channels/broadcast", payload: %{message: "hi"}}
    end

    test "broadcasts new events", %{state: state} do
      message = %Phoenix.Socket.Broadcast{
        topic: "system:backbone",
        event: "events/new",
        payload: %Version{action: "create", payload: %{title: "A Holiday"}}
      }

      Backbone.process_event(state, message)

      assert_receive {:broadcast, %{event: "sync/events"}}
    end

    test "broadcasts edited events", %{state: state} do
      message = %Phoenix.Socket.Broadcast{
        topic: "system:backbone",
        event: "events/edit",
        payload: %Version{action: "update", payload: %{title: "A Holiday"}}
      }

      Backbone.process_event(state, message)

      assert_receive {:broadcast, %{event: "sync/events"}}
    end

    test "broadcasts deleted events", %{state: state} do
      message = %Phoenix.Socket.Broadcast{
        topic: "system:backbone",
        event: "events/delete",
        payload: %Version{action: "delete", payload: %{id: 2, title: "A Holiday"}}
      }

      Backbone.process_event(state, message)

      assert_receive {:broadcast, %{event: "sync/events"}}
    end

    test "broadcasts new games", %{state: state} do
      message = %Phoenix.Socket.Broadcast{
        topic: "system:backbone",
        event: "games/new",
        payload: %Version{action: "create", payload: %{name: "game", connections: [], redirect_uris: []}}
      }

      Backbone.process_event(state, message)

      assert_receive {:broadcast, %{event: "sync/games"}}
    end

    test "broadcasts edited games", %{state: state} do
      message = %Phoenix.Socket.Broadcast{
        topic: "system:backbone",
        event: "games/edit",
        payload: %Version{action: "update", payload: %{name: "game", connections: [], redirect_uris: []}}
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

    test "limits based on a timestamp if present" do
      now = Timex.now()

      channel = create_channel(%{name: "gossip"})
      Enum.each(1..12, fn i ->
        Versions.log("update", channel, now |> Timex.shift(minutes: -1 * i))
      end)

      five_minutes_ago = Timex.now() |> Timex.shift(minutes: -5)
      Backbone.sync_channels(five_minutes_ago)

      assert_receive {:broadcast, %{event: "sync/channels"}}
      refute_receive {:broadcast, %{event: "sync/channels"}}
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

    test "limits based on a timestamp if present" do
      now = Timex.now()

      user = create_user()
      game = create_game(user)
      {:ok, game} = Games.get(game.id)

      Enum.each(1..12, fn i ->
        Versions.log("update", game, now |> Timex.shift(minutes: -1 * i))
      end)

      five_minutes_ago = Timex.now() |> Timex.shift(minutes: -5)
      Backbone.sync_games(five_minutes_ago)

      assert_receive {:broadcast, %{event: "sync/games"}}
      refute_receive {:broadcast, %{event: "sync/games"}}
    end
  end
end
