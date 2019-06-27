defmodule GrapevineData.Repo.Migrations.AddFeaturedOrderToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add(:featured_order, :integer)
    end
  end
end
