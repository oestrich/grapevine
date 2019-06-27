defmodule GrapevineData.Repo.Migrations.AddUniqueIndexOnConnections do
  use Ecto.Migration

  def change do
    create index(:connections, [:game_id, :type], unique: true)
  end
end
