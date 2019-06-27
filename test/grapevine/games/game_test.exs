defmodule GrapevineData.Games.GameTest do
  use Grapevine.DataCase

  alias GrapevineData.Games.Game

  setup do
    %{game: %Game{}}
  end

  describe "validations" do
    test "blocked list of names - name", %{game: game} do
      changeset =
        Game.changeset(game, %{
          name: "grapevine"
        })

      assert Keyword.has_key?(changeset.errors, :name)
    end

    test "matches the blocked name even different case - name", %{game: game} do
      changeset =
        Game.changeset(game, %{
          name: "GrApEvInE"
        })

      assert Keyword.has_key?(changeset.errors, :name)
    end

    test "blocked list of names - short name", %{game: game} do
      changeset =
        Game.changeset(game, %{
          short_name: "grapevine"
        })

      assert Keyword.has_key?(changeset.errors, :short_name)
    end

    test "matches the blocked name even different case - short name", %{game: game} do
      changeset =
        Game.changeset(game, %{
          short_name: "GrApEvInE"
        })

      assert Keyword.has_key?(changeset.errors, :short_name)
    end
  end
end
