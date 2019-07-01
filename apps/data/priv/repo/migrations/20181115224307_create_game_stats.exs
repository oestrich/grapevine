defmodule GrapevineData.Repo.Migrations.CreateGameStats do
  use Ecto.Migration

  def change do
    create table(:player_statistics) do
      add(:game_id, references(:games), null: false)
      add(:player_count, :integer, null: false)
      add(:recorded_at, :utc_datetime, null: false)
    end

    create index(:player_statistics, :game_id)
  end
end
