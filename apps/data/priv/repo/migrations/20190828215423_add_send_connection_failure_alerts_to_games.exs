defmodule GrapevineData.Repo.Migrations.AddSendConnectionFailureAlertsToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add(:send_connection_failure_alerts, :boolean, default: false, null: false)
    end
  end
end
