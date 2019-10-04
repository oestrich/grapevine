defmodule GrapevineData.EventsTest do
  use Grapevine.DataCase

  alias GrapevineData.Events

  describe "create a new event" do
    test "successful" do
      game = create_game(create_user())

      {:ok, event} =
        Events.create(game, %{
          title: "Adventuring",
          description: "Example description.",
          start_date: "2018-11-21",
          end_date: "2018-11-23"
        })

      assert event.title == "Adventuring"
      assert event.description == "Example description."
      assert event.start_date == ~D[2018-11-21]
      assert event.end_date == ~D[2018-11-23]
    end

    test "failure" do
      game = create_game(create_user())

      {:error, _changeset} =
        Events.create(game, %{
          title: "Adventuring",
          description: "Example description.",
          start_date: "2018-11-21",
          end_date: "2018-11-20"
        })
    end
  end

  describe "updating an event" do
    test "successful" do
      game = create_game(create_user())

      {:ok, event} =
        Events.create(game, %{
          title: "Adventuring",
          description: "Example description.",
          start_date: "2018-11-21",
          end_date: "2018-11-23"
        })

      {:ok, event} =
        Events.update(event, %{
          end_date: "2018-11-24"
        })

      assert event.end_date == ~D[2018-11-24]
    end
  end

  describe "deleting an event" do
    test "successful" do
      game = create_game(create_user())

      {:ok, event} =
        Events.create(game, %{
          title: "Adventuring",
          description: "Example description.",
          start_date: "2018-11-21",
          end_date: "2018-11-23"
        })

      {:ok, _event} = Events.delete(event)
    end
  end

  describe "incrementing the view count of an event" do
    test "successful" do
      game = create_game(create_user())

      {:ok, event} =
        Events.create(game, %{
          title: "Adventuring",
          description: "Example description.",
          start_date: "2018-11-21",
          end_date: "2018-11-23"
        })

      {:ok, event} = Events.inc_view_count(event)

      assert event.view_count == 1
    end
  end
end
