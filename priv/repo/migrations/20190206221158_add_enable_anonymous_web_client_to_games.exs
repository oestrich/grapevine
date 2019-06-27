defmodule GrapevineData.Repo.Migrations.AddEnableAnonymousWebClientToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add(:allow_anonymous_client, :boolean, default: false, null: false)
    end
  end
end
