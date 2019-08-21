defmodule Grapevine.Client.TellsTest do
  use Grapevine.DataCase

  alias GrapevineData.Accounts
  alias Grapevine.Client.Tells

  describe "receiving tells" do
    test "unknown operation" do
      :ok = Tells.receive_tell("ExVenture", "player", "hello")

      assert_receive {:tell, {"ExVenture", "player", "Hello! This is Grapevine" <> _}}
    end
  end

  describe "receiving a new tell to register a character" do
    test "receives a valid user code" do
      create_game(create_user(), %{short_name: "ExVenture"})

      user = create_user(%{username: "player", email: "player@example.com"})

      :ok = Tells.receive_tell("ExVenture", "player", "register #{user.registration_key}")

      message = "User registration initiated. Check your profile to complete registration!"
      assert_receive {:tell, {"ExVenture", "player", ^message}}
    end

    test "regenerates the user's key after receiving it" do
      create_game(create_user(), %{short_name: "ExVenture"})

      user = create_user(%{username: "player", email: "player@example.com"})

      :ok = Tells.receive_tell("ExVenture", "player", "register #{user.registration_key}")

      {:ok, new_user} = Accounts.get(user.id)
      assert new_user.registration_key != user.registration_key
    end

    test "the game disallows registration" do
      create_game(create_user(), %{short_name: "ExVenture", allow_character_registration: false})

      user = create_user(%{username: "player", email: "player@example.com"})

      :ok = Tells.receive_tell("ExVenture", "player", "register #{user.registration_key}")

      assert_receive {:tell, {"ExVenture", "player", "Your game does not" <> _}}
    end

    test "receives an invalid user code" do
      create_game(create_user(), %{short_name: "ExVenture"})

      :ok = Tells.receive_tell("ExVenture", "player", "register hi")

      assert_receive {:tell, {"ExVenture", "player", "Unknown registration key."}}
    end

    test "unknown game" do
      :ok = Tells.receive_tell("unknown", "to", "register hi")

      assert_receive {:tell, {_, _, "An unknown" <> _}}
    end
  end
end
