defmodule GrapevineData.Repo.Migrations.AddDescriptionsToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add(:description, :text)
    end
  end
end
