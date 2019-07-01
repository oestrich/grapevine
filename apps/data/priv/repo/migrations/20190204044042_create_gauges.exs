defmodule GrapevineData.Repo.Migrations.CreateGauges do
  use Ecto.Migration

  def change do
    create table(:gauges) do
      add(:game_id, references(:games), null: false)

      add(:name, :string, null: false)
      add(:package, :string, null: false)
      add(:message, :string, null: false)
      add(:value, :string, null: false)
      add(:max, :string, null: false)
      add(:color, :string, null: false)

      timestamps()
    end
  end
end
