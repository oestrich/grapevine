defmodule Grapevine.Games.ClientSettingsTest do
  use Grapevine.DataCase

  alias Grapevine.Games.ClientSettings

  describe "validations" do
    test "validates character_message and character_name_path are required together" do
      changeset = ClientSettings.changeset(%ClientSettings{}, %{})
      refute changeset.errors[:character_message]
      refute changeset.errors[:character_name_path]

      changeset = ClientSettings.changeset(%ClientSettings{}, %{character_message: "Char.Status"})
      refute changeset.errors[:character_message]
      assert changeset.errors[:character_name_path]

      changeset = ClientSettings.changeset(%ClientSettings{}, %{character_name_path: "name"})
      assert changeset.errors[:character_message]
      refute changeset.errors[:character_name_path]
    end
  end
end
