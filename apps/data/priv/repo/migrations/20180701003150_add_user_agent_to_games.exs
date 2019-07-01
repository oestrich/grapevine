defmodule GrapevineData.Repo.Migrations.AddUserAgentToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :user_agent, :string
    end
  end
end
