defmodule GrapevineData.Repo.Migrations.AddShortNameToGames do
  use Ecto.Migration

  def up do
    alter table(:games) do
      add :short_name, :string, size: 15
    end

    execute "update games set short_name = substring(name from 0 for 15);"

    alter table(:games) do
      modify :short_name, :string, size: 15, null: false
    end

    create index(:games, :short_name, unique: true)
  end

  def down do
    drop index(:games, :short_name)

    alter table(:games) do
      remove :short_name
    end
  end
end
