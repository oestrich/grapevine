defmodule GrapevineData.Repo.Migrations.AddRoleToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:role, :string, default: "user", null: false)
    end
  end
end
