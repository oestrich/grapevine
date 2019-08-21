defmodule GrapevineData.Repo.Migrations.CreateAchievements do
  use Ecto.Migration

  def change do
    create table(:achievements) do
      add(:game_id, references(:games), null: false)

      add(:title, :text, null: false)
      add(:description, :text)
      add(:display, :boolean, default: true, null: false)
      add(:points, :integer, null: false)
      add(:partial_progress, :boolean, default: false, null: false)
      add(:total_progress, :integer)

      timestamps()
    end
  end
end
