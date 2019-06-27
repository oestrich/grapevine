defmodule GrapevineData.Repo.Migrations.AddKeyToAchievements do
  use Ecto.Migration

  def change do
    alter table(:achievements) do
      add(:key, :uuid, default: fragment("uuid_generate_v4()"), null: false)
    end

    create index(:achievements, :key)
  end
end
