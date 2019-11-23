defmodule GrapevineData.Repo.Migrations.AddIsSilencedToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add(:can_broadcast, :boolean, default: true, null: false)
    end
  end
end
