defmodule GrapevineData.Repo.Migrations.AddDisplayToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :display, :boolean, default: true, null: false
    end
  end
end
