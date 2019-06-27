defmodule GrapevineData.Repo.Migrations.MoveUniqueIndexToLowercaseShortNameOnGames do
  use Ecto.Migration

  def up do
    alter table(:games) do
      add :short_name_downcase, :string
    end

    execute "update games set short_name_downcase = lower(short_name);"

    drop index(:games, :short_name)
    create index(:games, :short_name_downcase, unique: true)
  end

  def down do
    drop index(:games, :short_name_downcase)
    create index(:games, :short_name, unique: true)
  end
end
