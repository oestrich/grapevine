defmodule Socket.Handler.AchievementsTest do
  use Grapevine.DataCase

  alias Socket.Handler.Achievements
  alias Socket.Web.State

  describe "syncing the list of achievements" do
    test "successfully" do
      game = create_game(create_user())
      state = %State{game: game}
      create_achievement(game)

      frame = %{
        "event" => "achievements/sync",
        "ref" => UUID.uuid4()
      }

      {:ok, :skip, _state} = Achievements.sync(state, frame)

      assert_receive {:broadcast, %{"event" => "achievements/sync"}}, 50
    end

    test "no achievements" do
      game = create_game(create_user())
      state = %State{game: game}

      frame = %{
        "event" => "achievements/sync",
        "ref" => UUID.uuid4()
      }

      {:ok, :skip, _state} = Achievements.sync(state, frame)

      assert_receive {:broadcast, %{"event" => "achievements/sync"}}, 50
    end

    test "missing a ref" do
      game = create_game(create_user())
      state = %State{game: game}

      frame = %{
        "event" => "achievements/sync",
        "payload" => %{}
      }

      assert :error = Achievements.sync(state, frame)
    end
  end

  describe "creating new achievements" do
    test "successfully" do
      game = create_game(create_user())
      state = %State{game: game}

      frame = %{
        "event" => "achievements/create",
        "ref" => UUID.uuid4(),
        "payload" => %{
          "title" => "Adventuring",
          "description" => "You made it to level 2!",
          "points" => 10
        }
      }

      {:ok, response, _state} = Achievements.create(state, frame)

      assert response["payload"].title == "Adventuring"
    end

    test "failure" do
      game = create_game(create_user())
      state = %State{game: game}

      frame = %{
        "event" => "achievements/create",
        "ref" => UUID.uuid4(),
        "payload" => %{}
      }

      {:ok, response, _state} = Achievements.create(state, frame)

      assert response["payload"]["errors"].title
    end

    test "missing a ref" do
      game = create_game(create_user())
      state = %State{game: game}

      frame = %{
        "event" => "achievements/create",
        "payload" => %{}
      }

      assert :error = Achievements.create(state, frame)
    end
  end

  describe "updating an achievement" do
    test "successfully" do
      game = create_game(create_user())
      state = %State{game: game}

      achievement =
        create_achievement(game, %{
          "name" => "Title"
        })

      frame = %{
        "event" => "achievements/update",
        "ref" => UUID.uuid4(),
        "payload" => %{
          "key" => achievement.key,
          "title" => "Updated"
        }
      }

      {:ok, response, _state} = Achievements.update(state, frame)

      assert response["payload"].title == "Updated"
    end

    test "failure" do
      game = create_game(create_user())
      state = %State{game: game}

      achievement = create_achievement(game)

      frame = %{
        "event" => "achievements/update",
        "ref" => UUID.uuid4(),
        "payload" => %{
          "key" => achievement.key,
          "title" => nil
        }
      }

      {:ok, response, _state} = Achievements.update(state, frame)

      assert response["payload"]["errors"].title
    end

    test "key not found" do
      game = create_game(create_user())
      state = %State{game: game}

      frame = %{
        "event" => "achievements/update",
        "ref" => UUID.uuid4(),
        "payload" => %{}
      }

      {:ok, response, _state} = Achievements.update(state, frame)

      assert response["payload"]["errors"]["key"]
    end

    test "missing a ref" do
      game = create_game(create_user())
      state = %State{game: game}

      frame = %{
        "event" => "achievements/update",
        "payload" => %{}
      }

      assert :error = Achievements.update(state, frame)
    end
  end

  describe "deleting achievements" do
    test "successfully" do
      game = create_game(create_user())
      state = %State{game: game}

      achievement =
        create_achievement(game, %{
          "name" => "Title"
        })

      frame = %{
        "event" => "achievements/delete",
        "ref" => UUID.uuid4(),
        "payload" => %{
          "key" => achievement.key
        }
      }

      {:ok, response, _state} = Achievements.delete(state, frame)

      assert response["ref"]
    end

    test "key not found" do
      game = create_game(create_user())
      state = %State{game: game}

      frame = %{
        "event" => "achievements/update",
        "ref" => UUID.uuid4(),
        "payload" => %{}
      }

      {:ok, response, _state} = Achievements.delete(state, frame)

      assert response["payload"]["errors"]["key"]
    end

    test "missing a ref" do
      game = create_game(create_user())
      state = %State{game: game}

      frame = %{
        "event" => "achievements/update",
        "payload" => %{}
      }

      assert :error = Achievements.delete(state, frame)
    end
  end
end
