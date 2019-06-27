defmodule GrapevineData.Repo.Migrations.CreateCharacters do
  use Ecto.Migration

  def change do
    create table(:characters) do
      add(:user_id, references(:users))
      add(:game_id, references(:games), null: false)
      add(:name, :string, null: false)
      add(:state, :string, default: "pending")

      timestamps()
    end

    alter table(:users) do
      add(:registration_key, :uuid, default: fragment("uuid_generate_v4()"), null: false)
    end

    create index(:characters, [:game_id, :name], unique: true)
  end
end
