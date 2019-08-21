defmodule GrapevineData.Repo.Migrations.AddTaglineToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add(:tagline, :string)
    end
  end
end
