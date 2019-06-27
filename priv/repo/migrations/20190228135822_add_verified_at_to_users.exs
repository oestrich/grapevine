defmodule GrapevineData.Repo.Migrations.AddVerifiedAtToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:email_verification_token, :uuid)
      add(:email_verified_at, :utc_datetime)
    end
  end
end
