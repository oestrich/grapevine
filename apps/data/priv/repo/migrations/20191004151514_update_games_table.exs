defmodule GrapevineData.Repo.Migrations.UpdateGamesTable do
  use Ecto.Migration

  def up do
    execute "UPDATE games SET description = '' WHERE description IS NULL"
    alter table(:games) do
      modify :description, :text, null: false
    end
  end

  def down do
    alter table(:games) do
      modify :description, :text, null: true
    end
    execute "UPDATE games SET description = NULL WHERE description = ''"
  end
end
