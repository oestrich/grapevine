defmodule GrapevineData.Repo.Migrations.ChangeLowerShortnameIndexOnGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      remove :short_name_downcase
    end

    create index(:games, ["lower(name)"], unique: true, name: :games_lower_name_index)
    create index(:games, ["lower(short_name)"], unique: true, name: :games_lower_short_name_index)
  end

  def down do
    drop index(:games, ["lower(name)"], name: :games_lower_name_index)
    drop index(:games, ["lower(short_name)"], name: :games_lower_short_name_index)

    alter table(:games) do
      add :short_name_downcase, :string
    end

    execute "update games set short_name_downcase = lower(short_name);"

    create index(:games, :short_name_downcase, unique: true)
  end
end
