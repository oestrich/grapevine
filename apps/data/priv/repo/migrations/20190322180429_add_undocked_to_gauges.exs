defmodule GrapevineData.Repo.Migrations.AddUndockedToGauges do
  use Ecto.Migration

  def change do
    alter table(:gauges) do
      add(:is_docked, :boolean, default: true, null: false)
    end
  end
end
