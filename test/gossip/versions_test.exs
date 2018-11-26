defmodule Gossip.VersionsTest do
  use Gossip.DataCase

  alias Gossip.Games
  alias Gossip.Versions

  describe "log a new action" do
    test "create action" do
      game = create_game(create_user())
      {:ok, game} = Games.get(game.id)

      {:ok, version} = Versions.log("create", game)

      assert version.action == "create"
      assert version.schema == "games"
      assert version.schema_id == game.id
      assert version.payload.id == game.id
    end

    test "update action" do
      game = create_game(create_user())
      {:ok, game} = Games.get(game.id)

      {:ok, version} = Versions.log("update", game)

      assert version.action == "update"
      assert version.schema == "games"
      assert version.schema_id == game.id
      assert version.payload.id == game.id
    end
  end
end
