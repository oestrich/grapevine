defmodule GrapevineData.Repo.Migrations.CreateMsspResponses do
  use Ecto.Migration

  def change do
    create table(:mssp_responses) do
      add(:host, :string, null: false)
      add(:port, :integer, null: false)
      add(:supports_mssp, :boolean, default: false, null: false)
      add(:data, :jsonb, null: false)

      timestamps()
    end
  end
end
