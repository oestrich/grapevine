defmodule GrapevineData.Repo.Migrations.BreakGamesAndUsersUp do
  use Ecto.Migration

  def up do
    drop index(:games, :name)
    drop index(:games, :email)

    rename table(:games), to: table(:users)

    create table(:games) do
      add :user_id, references(:users), null: false
      add :name, :string, null: false
      add :client_id, :uuid, null: false
      add :client_secret, :uuid, null: false
      add :user_agent, :string

      timestamps()
    end

    create index(:games, :name, unique: true)
    create index(:users, :email, unique: true)

    execute """
    insert into games (user_id, name, client_id, client_secret, user_agent, inserted_at, updated_at)
    select id as user_id, name, client_id, client_secret, user_agent, inserted_at, updated_at from users;
    """

    alter table(:users) do
      remove :name
      remove :client_id
      remove :client_secret
      remove :user_agent
    end

    execute "truncate subscribed_channels"

    alter table(:subscribed_channels) do
      remove :game_id
      add :game_id, references(:games), null: false
      modify :channel_id, :integer, null: false
    end
  end

  def down do
    #raise "Can't go back"
  end
end
