defmodule GrapevineData.Repo.Migrations.RemoveSubscribedChannels do
  use Ecto.Migration

  def change do
    drop table(:subscribed_channels)
  end
end
