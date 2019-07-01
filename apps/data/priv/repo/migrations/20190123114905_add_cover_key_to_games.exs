defmodule GrapevineData.Repo.Migrations.AddCoverKeyToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add(:cover_key, :uuid)
    end
  end
end
