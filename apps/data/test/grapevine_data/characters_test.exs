defmodule GrapevineData.CharactersTest do
  use Grapevine.DataCase

  alias GrapevineData.Characters

  describe "registration" do
    test "starts registration" do
      user = create_user(%{username: "player", email: "user@example.com"})
      game = create_game(create_user())

      {:ok, character} = Characters.start_registration(user, game, "Player")

      assert character.user_id == user.id
      assert character.game_id == game.id
      assert character.name == "Player"
      assert character.state == "pending"
    end
  end

  describe "finalize character registration" do
    test "marks as approved" do
      user = create_user(%{username: "player", email: "user@example.com"})
      game = create_game(create_user())

      {:ok, character} = Characters.start_registration(user, game, "Player")
      {:ok, character} = Characters.approve_character(character)

      assert character.state == "approved"
    end
  end

  describe "deny character registration" do
    test "marks as rejected" do
      user = create_user(%{username: "player", email: "user@example.com"})
      game = create_game(create_user())

      {:ok, character} = Characters.start_registration(user, game, "Player")
      {:ok, character} = Characters.deny_character(character)

      assert character.state == "denied"
    end
  end
end
