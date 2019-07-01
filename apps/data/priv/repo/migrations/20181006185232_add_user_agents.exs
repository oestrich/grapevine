defmodule GrapevineData.Repo.Migrations.AddUserAgents do
  use Ecto.Migration

  def change do
    create table(:user_agents) do
      add :version, :string, null: false
      add :repo_url, :text

      timestamps()
    end

    create index(:user_agents, :version, unique: true)
  end
end
