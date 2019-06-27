defmodule GrapevineData.Repo.Migrations.CreateChannels do
  use Ecto.Migration

  def change do
    create table(:channels) do
      add :name, :string, null: false
      add :description, :text

      timestamps()
    end

    create index(:channels, :name, unique: true)

    create table(:subscribed_channels) do
      add :game_id, references(:games)
      add :channel_id, references(:channels)
    end

    create index(:subscribed_channels, :game_id)
  end
end
