defmodule Grapevine.Repo.Migrations.AddDisplayPlayersToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add(:display_players, :boolean, default: true, null: false)
    end
  end
end
