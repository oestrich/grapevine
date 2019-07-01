defmodule GrapevineData.Repo.Migrations.AddCovertExtensionToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add(:cover_extension, :string)
    end
  end
end
