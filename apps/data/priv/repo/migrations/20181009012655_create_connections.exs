defmodule GrapevineData.Repo.Migrations.CreateConnections do
  use Ecto.Migration

  def change do
    create table(:connections) do
      add(:game_id, references(:games), null: false)

      add(:type, :string, null: false)
      add(:url, :string)
      add(:host, :string)
      add(:port, :integer)

      timestamps()
    end
  end
end
