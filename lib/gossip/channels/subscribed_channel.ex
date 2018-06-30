defmodule Gossip.Channels.SubscribedChannel do
  use Gossip.Schema

  alias Gossip.Channels.Channel
  alias Gossip.Games.Game

  schema "subscribed_channels" do
    belongs_to :channel, Channel
    belongs_to :game, Game
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:channel_id, :game_id])
    |> validate_required([:channel_id, :game_id])
    |> foreign_key_constraint(:channel_id)
    |> foreign_key_constraint(:game_id)
  end
end
