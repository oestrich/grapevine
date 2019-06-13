defmodule Grapevine.Messages.Message do
  @moduledoc """
  Message Schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Grapevine.Channels.Channel
  alias Grapevine.Games.Game

  @type t :: %__MODULE__{}

  schema "messages" do
    field(:name, :string)
    field(:text, :string)

    belongs_to(:game, Game)
    belongs_to(:channel, Channel)

    timestamps(updated_at: false)
  end

  def create_changeset(struct, game, channel, params) do
    struct
    |> cast(params, [:name, :text])
    |> validate_required([:name, :text])
    |> put_change(:game_id, game.id)
    |> put_change(:channel_id, channel.id)
    |> foreign_key_constraint(:channel_id)
    |> foreign_key_constraint(:game_id)
  end
end
