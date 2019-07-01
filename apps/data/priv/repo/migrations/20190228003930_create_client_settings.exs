defmodule GrapevineData.Repo.Migrations.CreateClientSettings do
  use Ecto.Migration

  def change do
    create table(:client_settings) do
      add(:game_id, references(:games), null: false)

      add(:character_package, :string)
      add(:character_message, :string)
      add(:character_name_path, :string)

      timestamps()
    end
  end
end
