defmodule GrapevineData.Repo.Migrations.AddMsspLastSeenAtToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add(:mssp_last_seen_at, :utc_datetime)
    end
  end
end
