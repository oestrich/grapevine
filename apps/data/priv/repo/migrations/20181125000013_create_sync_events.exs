defmodule GrapevineData.Repo.Migrations.CreateSyncEvents do
  use Ecto.Migration

  def change do
    create table(:versions) do
      add(:action, :string, null: false)
      add(:schema, :string, null: false)
      add(:schema_id, :integer, null: false)
      add(:payload, :jsonb, null: false)
      add(:logged_at, :utc_datetime)
    end

    create index(:versions, [:schema, :logged_at])
  end
end
