defmodule GrapevineData.AchievementsTest do
  use Grapevine.DataCase

  alias GrapevineData.Achievements

  describe "create a new achievement" do
    test "successful" do
      game = create_game(create_user())

      {:ok, achievement} =
        Achievements.create(game, %{
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

    test "limited to 500 points total for a game" do
      game = create_game(create_user())

      Enum.each(1..5, fn _ ->
        {:ok, _achievement} =
          Achievements.create(game, %{
            title: "Achievement",
            points: 100
          })
      end)

      {:error, changeset} =
        Achievements.create(game, %{
          title: "Achievement",
          points: 10
        })

      assert changeset.errors[:points]
    end
  end

  describe "updating an achievement" do
    test "successful" do
      game = create_game(create_user())

      {:ok, achievement} =
        Achievements.create(game, %{
          title: "Adventuring",
          description: "You made it to level 2!",
          points: 10
        })

      {:ok, achievement} =
        Achievements.update(achievement, %{
          points: 11
        })

      assert achievement.points == 11
    end
  end

  describe "deleting an achievement" do
    test "successful" do
      game = create_game(create_user())

      {:ok, achievement} =
        Achievements.create(game, %{
          title: "Adventuring",
          description: "You made it to level 2!",
          points: 10
        })

      {:ok, _achievement} = Achievements.delete(achievement)
    end
  end

  describe "total points for a game" do
    test "sums up the total" do
      game = create_game(create_user())

      Enum.each(1..5, fn _ ->
        {:ok, _achievement} =
          Achievements.create(game, %{
            title: "Achievement",
            points: 10
          })
      end)

      assert Achievements.total_points(game) == 50
    end

    test "no achievements yet is 0" do
      game = create_game(create_user())

      assert Achievements.total_points(game) == 0
    end
  end
end
