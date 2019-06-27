defmodule GrapevineData.Repo.Migrations.AddHasMsspToConnections do
  use Ecto.Migration

  def change do
    alter table(:connections) do
      add(:supports_mssp, :boolean, default: false, null: false)
    end
  end
end
