defmodule GrapevineData.Repo.Migrations.AddUsecToInsertedAtMessages do
  use Ecto.Migration

  def up do
    alter table(:messages) do
      modify(:inserted_at, :utc_datetime_usec)
    end
  end

  def down do
    alter table(:messages) do
      modify(:inserted_at, :utc_datetime)
    end
  end
end
