defmodule GrapevineData.Repo.Migrations.CreateAlerts do
  use Ecto.Migration

  def change do
    create table(:alerts) do
      add(:title, :string)
      add(:body, :text)

      timestamps()
    end
  end
end
