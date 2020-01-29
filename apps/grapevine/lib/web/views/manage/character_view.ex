defmodule Web.Manage.CharacterView do
  use Web, :view

  alias Web.Manage.SettingView

  def pending_characters(characters) do
    Enum.filter(characters, &(&1.state == "pending"))
  end

  def approved_characters(characters) do
    Enum.filter(characters, &(&1.state == "approved"))
  end
end
