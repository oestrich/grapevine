defmodule Grapevine.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add(:channel_id, references(:channels), null: false)
      add(:game_id, references(:games), null: false)
      add(:name, :text, null: false)
      add(:text, :text, null: false)

      timestamps(updated_at: false)
    end
  end
end
