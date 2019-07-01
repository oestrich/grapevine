defmodule GrapevineData.Repo.Migrations.AddLastSeenAtToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add(:last_seen_at, :utc_datetime)
    end

    create index(:games, :last_seen_at)
  end
end
