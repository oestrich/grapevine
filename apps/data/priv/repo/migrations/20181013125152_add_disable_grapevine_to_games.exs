defmodule GrapevineData.Repo.Migrations.AddDisableGrapevineToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add(:allow_character_registration, :boolean, default: true, null: false)
    end
  end
end
