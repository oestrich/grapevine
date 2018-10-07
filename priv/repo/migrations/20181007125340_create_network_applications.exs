defmodule Gossip.Repo.Migrations.CreateNetworkApplications do
  use Ecto.Migration

  def change do
    create table(:applications) do
      add(:short_name, :string)
      add(:client_id, :uuid)
      add(:client_secret, :uuid)

      timestamps()
    end

    create index(:applications, ["lower(short_name)"], unique: true, name: :applications_lower_short_name_index)
    create index(:applications, :client_id, unique: true)
  end
end
