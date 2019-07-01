defmodule GrapevineData.Repo.Migrations.AddCertToConnections do
  use Ecto.Migration

  def change do
    alter table(:connections) do
      add(:certificate, :text)
    end
  end
end
