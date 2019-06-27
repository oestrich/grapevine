defmodule GrapevineData.Repo.Migrations.AddCnameToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add(:cname, :string)
    end

    create index(:games, :cname, unique: true)
  end
end
