defmodule GrapevineData.Repo.Migrations.AddHostedSettingsToGames do
  use Ecto.Migration

  def change do
    create table(:hosted_settings) do
      add(:game_id, references(:games), null: false)
      add(:welcome_text, :text)

      timestamps()
    end
  end
end
