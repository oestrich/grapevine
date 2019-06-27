defmodule GrapevineData.Repo.Migrations.AddNewEnvironToClientSettings do
  use Ecto.Migration

  def change do
    alter table(:client_settings) do
      add(:new_environ_enabled, :boolean, default: false, null: false)
    end
  end
end
