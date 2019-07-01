defmodule GrapevineData.Statistics.PlayerStatistic do
  @moduledoc """
  Player Statistic Schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias GrapevineData.Games.Game

  @type t :: %__MODULE__{}

  schema "player_statistics" do
    field(:type, :string)
    field(:player_count, :integer)
    field(:player_names, {:array, :string})
    field(:recorded_at, :utc_datetime)

    belongs_to(:game, Game)
  end

  def socket_changeset(struct, game, players, recorded_time) do
    struct
    |> change()
    |> put_change(:type, "socket")
    |> put_change(:game_id, game.id)
    |> put_change(:player_count, length(players))
    |> put_change(:player_names, players)
    |> put_change(:recorded_at, DateTime.truncate(recorded_time, :second))
    |> foreign_key_constraint(:game_id)
  end

  def mssp_changeset(struct, game, player_count, recorded_time) do
    struct
    |> change()
    |> put_change(:type, "mssp")
    |> put_change(:game_id, game.id)
    |> put_change(:player_count, player_count)
    |> put_change(:player_names, [])
    |> put_change(:recorded_at, DateTime.truncate(recorded_time, :second))
    |> foreign_key_constraint(:game_id)
  end
end
