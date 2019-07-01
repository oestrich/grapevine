defmodule GrapevineData.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :name, :string, null: false
      add :email, :string, null: false
      add :password_hash, :string, null: false

      add :token, :uuid
      add :client_id, :uuid
      add :client_secret, :uuid

      timestamps()
    end

    create index(:games, :name, unique: true)
    create index(:games, :email, unique: true)
  end
end
