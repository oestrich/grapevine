defmodule Gossip.Statistics.PlayerStatistic do
  @moduledoc """
  Player Statistic Schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Gossip.Games.Game

  @type t :: %__MODULE__{}

  schema "player_statistics" do
    field(:player_count, :integer)
    field(:recorded_at, :utc_datetime)

    belongs_to(:game, Game)
  end

  def changeset(struct, game, player_count, recorded_time) do
    struct
    |> change()
    |> put_change(:game_id, game.id)
    |> put_change(:player_count, player_count)
    |> put_change(:recorded_at, DateTime.truncate(recorded_time, :second))
    |> foreign_key_constraint(:game_id)
  end
end
