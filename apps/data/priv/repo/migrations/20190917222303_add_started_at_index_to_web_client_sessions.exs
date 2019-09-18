defmodule GrapevineData.Repo.Migrations.AddStartedAtIndexToWebClientSessions do
  use Ecto.Migration

  def change do
    create index(:web_client_sessions, [:started_at])
  end
end
