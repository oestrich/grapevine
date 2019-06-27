defmodule GrapevineData.Repo.Migrations.AddUuidToEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add(:uid, :uuid, default: fragment("uuid_generate_v4()"), null: false)
    end

    create index(:events, :uid)
  end
end
