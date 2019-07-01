defmodule GrapevineData.Repo.Migrations.AddDiscordInviteToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add(:discord_invite_url, :text)
    end
  end
end
