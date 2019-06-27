defmodule GrapevineData.Repo.Migrations.CreateOauthTables do
  use Ecto.Migration

  def change do
    create table(:authorizations) do
      add(:game_id, references(:games), null: false)
      add(:user_id, references(:users), null: false)
      add(:redirect_uri, :text, null: false)
      add(:state, :text)
      add(:scopes, {:array, :text}, default: fragment("'{}'"), null: false)
      add(:code, :uuid)
      add(:active, :boolean, default: false, null: false)

      timestamps()
    end

    create table(:access_tokens, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:authorization_id, references(:authorizations), null: false)
      add(:access_token, :uuid, null: false)
      add(:refresh_token, :uuid, null: false)
      add(:active, :boolean, default: false, null: false)
      add(:expires_in, :integer, null: false)

      timestamps()
    end

    create index(:authorizations, :code, unique: true)

    create index(:access_tokens, :access_token, unique: true)
    create index(:access_tokens, :refresh_token, unique: true)
  end
end
