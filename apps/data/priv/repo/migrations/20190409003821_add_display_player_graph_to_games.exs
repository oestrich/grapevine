defmodule GrapevineData.Repo.Migrations.AddDisplayPlayerGraphToGames do
  use Ecto.Migration

  def up do
    alter table(:games) do
      add(:display_player_graph, :boolean, default: false)
    end

    rename table(:games), :mssp_last_seen_at, to: :telnet_last_seen_at

    execute """
    update games set display_player_graph = (select supports_mssp from connections where connections.game_id = games.id and connections.type = 'telnet');
    """

    alter table(:connections) do
      add(:poll_enabled, :boolean, default: false)
    end

    execute """
    update connections set poll_enabled = supports_mssp;
    """
  end

  def down do
    alter table(:connections) do
      remove(:poll_enabled)
    end

    rename table(:games), :telnet_last_seen_at, to: :mssp_last_seen_at

    alter table(:games) do
      remove(:display_player_graph)
    end
  end
end
