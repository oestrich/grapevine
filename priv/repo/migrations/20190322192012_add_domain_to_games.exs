defmodule GrapevineData.Repo.Migrations.AddDomainToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add(:site_cname, :string)
    end

    rename table(:games), :cname, to: :client_cname

    create index(:games, :site_cname, unique: true)
  end
end
