defmodule GrapevineData.Repo.Migrations.AddOauthFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:uid, :uuid, default: fragment("uuid_generate_v4()"), null: false)
      add(:username, :string)
    end

    create index(:users, :uid, unique: true)
    create index(:users, :username, unique: true)
  end
end
