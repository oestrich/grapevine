defmodule GrapevineData.Repo.Migrations.AddRedirectUrisToGames do
  use Ecto.Migration

  def change do
    create table(:redirect_uris) do
      add(:game_id, references(:games), null: false)
      add(:uri, :text, null: false)

      timestamps()
    end
  end
end
