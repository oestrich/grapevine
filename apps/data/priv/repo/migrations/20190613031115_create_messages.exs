defmodule GrapevineData.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add(:channel, :text, null: false)
      add(:game, :text, null: false)
      add(:name, :text, null: false)
      add(:text, :text, null: false)

      add(:channel_id, references(:channels), null: false)
      add(:game_id, references(:games))
      add(:user_id, references(:users))

      timestamps(updated_at: false)
    end
  end
end
