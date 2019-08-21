defmodule GrapevineData.Repo.Migrations.AddApiIdToConnections do
  use Ecto.Migration

  def up do
    execute ~s(create extension "uuid-ossp";)

    alter table(:connections) do
      add(:key, :uuid, default: fragment("uuid_generate_v4()"), null: false)
    end
  end

  def down do
    alter table(:connections) do
      remove(:key)
    end

    execute ~s(drop extension "uuid-ossp";)
  end
end
