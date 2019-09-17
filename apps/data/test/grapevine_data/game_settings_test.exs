defmodule GrapevineData.GameSettingsTest do
  use Grapevine.DataCase

  alias GrapevineData.GameSettings

  describe "update client settings" do
    test "when none exist" do
      game = create_game(create_user())

      {:ok, client_settings} = GameSettings.update_client_settings(game, %{
        character_package: "Char 0",
        character_message: "Char.Status",
        character_name_path: "name"
      })

      assert client_settings.game_id == game.id
      assert client_settings.character_package == "Char 0"
      assert client_settings.character_message == "Char.Status"
      assert client_settings.character_name_path == "name"
    end

    test "updating existing" do
      game = create_game(create_user())

      {:ok, _client_settings} = GameSettings.update_client_settings(game, %{
        character_package: "Char 0",
        character_message: "Char.Status",
        character_name_path: "name"
      })

      {:ok, client_settings} = GameSettings.update_client_settings(game, %{
        character_name_path: "full_name"
      })

      assert client_settings.character_name_path == "full_name"
    end
  end

  describe "update hosted settings" do
    test "when none exist" do
      game = create_game(create_user())

      {:ok, hosted_settings} = GameSettings.update_hosted_settings(game, %{
        welcome_text: "Howdy"
      })

      assert hosted_settings.game_id == game.id
      assert hosted_settings.welcome_text == "Howdy"
    end

    test "updating existing" do
      game = create_game(create_user())

      {:ok, _hosted_settings} = GameSettings.update_hosted_settings(game, %{
        welcome_text: "Howdy Old"
      })

      {:ok, hosted_settings} = GameSettings.update_hosted_settings(game, %{
        welcome_text: "Howdy New"
      })

      assert hosted_settings.welcome_text == "Howdy New"
    end
  end
end
