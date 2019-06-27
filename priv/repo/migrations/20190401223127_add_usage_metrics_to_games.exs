defmodule GrapevineData.Repo.Migrations.AddUsageMetricsToGames do
  use Ecto.Migration

  def change do
    create table(:web_client_sessions) do
      add(:sid, :uuid, null: false)

      add(:game_id, references(:games), null: false)

      add(:started_at, :utc_datetime, null: true)
      add(:closed_at, :utc_datetime, null: true)
    end

    create index(:web_client_sessions, :sid, unique: true)
    create index(:web_client_sessions, :game_id)
  end
end
