defmodule Gossip.Achievements.AchievementTest do
  use Gossip.DataCase

  alias Gossip.Achievements.Achievement

  describe "validations" do
    test "validating total progress is required if partial progress is true" do
      changeset = %Achievement{} |> Achievement.changeset(%{partial_progress: false})
      refute changeset.errors[:total_progress]

      changeset = %Achievement{} |> Achievement.changeset(%{partial_progress: true})
      assert changeset.errors[:total_progress]
    end
  end
end
