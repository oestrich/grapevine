defmodule GrapevineData.GameSettings.ClientSettingsTest do
  use Grapevine.DataCase

  alias GrapevineData.GameSettings.ClientSettings

  describe "validations" do
    test "validates character_message and character_name_path are required together" do
      changeset = ClientSettings.changeset(%ClientSettings{}, %{})
      refute changeset.errors[:character_package]
      refute changeset.errors[:character_message]
      refute changeset.errors[:character_name_path]

      changeset = ClientSettings.changeset(%ClientSettings{}, %{character_package: "Char 0"})
      refute changeset.errors[:character_package]
      assert changeset.errors[:character_message]
      assert changeset.errors[:character_name_path]

      changeset = ClientSettings.changeset(%ClientSettings{}, %{character_message: "Char.Status"})
      assert changeset.errors[:character_package]
      refute changeset.errors[:character_message]
      assert changeset.errors[:character_name_path]

      changeset = ClientSettings.changeset(%ClientSettings{}, %{character_name_path: "name"})
      assert changeset.errors[:character_package]
      assert changeset.errors[:character_message]
      refute changeset.errors[:character_name_path]
    end
  end
end
