defmodule GrapevineData.Repo.Migrations.AddHiddenToChannels do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :hidden, :boolean, default: true, null: false
    end
  end
end
