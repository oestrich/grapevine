defmodule GrapevineData.Repo.Migrations.CreateNetworkApplications do
  use Ecto.Migration

  def change do
    create table(:applications) do
      add(:name, :string, null: false)
      add(:short_name, :string, null: false)
      add(:client_id, :uuid, null: false)
      add(:client_secret, :uuid, null: false)

      timestamps()
    end

    create index(:applications, ["lower(name)"], unique: true, name: :applications_lower_name_index)
    create index(:applications, ["lower(short_name)"], unique: true, name: :applications_lower_short_name_index)
    create index(:applications, :client_id, unique: true)
  end
end
