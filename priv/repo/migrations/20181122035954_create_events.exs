defmodule GrapevineData.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add(:game_id, references(:games), null: false)
      add(:title, :text, null: false)
      add(:description, :text)
      add(:start_date, :date)
      add(:end_date, :date)

      timestamps()
    end
  end
end
