defmodule GrapevineData.Messages.Message do
  @moduledoc """
  Message Schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias GrapevineData.Accounts.User
  alias GrapevineData.Channels.Channel
  alias GrapevineData.Games.Game

  @type t :: %__MODULE__{}

  schema "messages" do
    field(:channel, :string)
    field(:game, :string)
    field(:name, :string)
    field(:text, :string)

    belongs_to(:channel_record, Channel, foreign_key: :channel_id)
    belongs_to(:game_record, Game, foreign_key: :game_id)
    belongs_to(:user_record, User, foreign_key: :user_id)

    timestamps(updated_at: false)
  end

  def create_socket_changeset(struct, game, channel, params) do
    struct
    |> cast(params, [:name, :text])
    |> validate_required([:name, :text])
    |> put_change(:game, game.short_name)
    |> put_change(:channel, channel.name)
    |> put_change(:game_id, game.id)
    |> put_change(:channel_id, channel.id)
    |> foreign_key_constraint(:channel_id)
    |> foreign_key_constraint(:game_id)
  end

  def create_web_changeset(struct, channel, user, text) do
    struct
    |> cast(%{text: text}, [:text])
    |> validate_required([:text])
    |> put_change(:game, "Grapevine")
    |> put_change(:channel, channel.name)
    |> put_change(:name, user.username)
    |> put_change(:user_id, user.id)
    |> put_change(:channel_id, channel.id)
    |> foreign_key_constraint(:channel_id)
    |> foreign_key_constraint(:user_id)
  end
end
