defmodule GrapevineData.Repo.Migrations.AddEventViewCountToEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :view_count, :integer, default: 0, null: false
    end
  end
end
