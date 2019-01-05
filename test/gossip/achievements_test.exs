defmodule Gossip.AchievementsTest do
  use Gossip.DataCase

  alias Gossip.Achievements

  describe "create a new achievement" do
    test "successful" do
      game = create_game(create_user())

      {:ok, achievement} = Achievements.create(game, %{
        title: "Level 2",
        description: "You made it to level 2!",
        points: 10
      })

      assert achievement.title == "Level 2"
      assert achievement.description
      assert achievement.points == 10
    end

    test "failure" do
      game = create_game(create_user())

      {:error, _changeset} = Achievements.create(game, %{})
    end
  end

  describe "updating an achievement" do
    test "successful" do
      game = create_game(create_user())

      {:ok, achievement} = Achievements.create(game, %{
        title: "Adventuring",
        description: "You made it to level 2!",
        points: 10
      })

      {:ok, achievement} = Achievements.update(achievement, %{
        points: 11
      })

      assert achievement.points == 11
    end
  end

  describe "deleting an achievement" do
    test "successful" do
      game = create_game(create_user())

      {:ok, achievement} = Achievements.create(game, %{
        title: "Adventuring",
        description: "You made it to level 2!",
        points: 10
      })

      {:ok, _achievement} = Achievements.delete(achievement)
    end
  end
end
