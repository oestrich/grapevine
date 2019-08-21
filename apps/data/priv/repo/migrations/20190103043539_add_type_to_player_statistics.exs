defmodule GrapevineData.Repo.Migrations.AddTypeToPlayerStatistics do
  use Ecto.Migration

  def change do
    alter table(:player_statistics) do
      add(:type, :string, default: "socket", null: false)
    end
  end
end
