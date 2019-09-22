defmodule GrapevineData.Repo.Migrations.RemoveNullOnGameIdFromEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      modify(:game_id, :integer, null: true)
    end
  end
end
