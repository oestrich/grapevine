defmodule GrapevineData.Achievements.AchievementTest do
  use Grapevine.DataCase

  alias GrapevineData.Achievements.Achievement

  describe "validations" do
    test "validating total progress is required if partial progress is true" do
      changeset = %Achievement{} |> Achievement.changeset(%{partial_progress: false})
      refute changeset.errors[:total_progress]

      changeset = %Achievement{} |> Achievement.changeset(%{partial_progress: true})
      assert changeset.errors[:total_progress]
    end

    test "points must be < 100" do
      changeset = %Achievement{} |> Achievement.changeset(%{points: 10})
      refute changeset.errors[:points]

      changeset = %Achievement{} |> Achievement.changeset(%{points: 101})
      assert changeset.errors[:points]
    end

    test "points must be > 0" do
      changeset = %Achievement{} |> Achievement.changeset(%{points: 10})
      refute changeset.errors[:points]

      changeset = %Achievement{} |> Achievement.changeset(%{points: -1})
      assert changeset.errors[:points]
    end
  end
end
