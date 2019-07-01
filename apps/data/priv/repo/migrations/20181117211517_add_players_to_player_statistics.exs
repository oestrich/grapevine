defmodule GrapevineData.Repo.Migrations.AddPlayersToPlayerStatistics do
  use Ecto.Migration

  def change do
    alter table(:player_statistics) do
      add(:player_names, {:array, :text}, default: fragment("'{}'"), null: false)
    end
  end
end
