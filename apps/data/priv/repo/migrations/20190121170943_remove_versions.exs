defmodule GrapevineData.Repo.Migrations.RemoveVersions do
  use Ecto.Migration

  def up do
    drop table(:versions)
  end

  def down do
    raise "No going back"
  end
end
