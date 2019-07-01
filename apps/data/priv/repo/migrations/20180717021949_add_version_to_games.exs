defmodule GrapevineData.Repo.Migrations.AddVersionToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :version, :string
    end
  end
end
