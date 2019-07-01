defmodule GrapevineData.Repo.Migrations.AddLinksToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :homepage_url, :string
    end
  end
end
