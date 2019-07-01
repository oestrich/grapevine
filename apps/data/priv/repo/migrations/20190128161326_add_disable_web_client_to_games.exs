defmodule GrapevineData.Repo.Migrations.AddDisableWebClientToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add(:enable_web_client, :boolean, default: false, null: false)
    end
  end
end
