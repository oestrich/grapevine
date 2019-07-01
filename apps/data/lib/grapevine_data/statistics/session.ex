defmodule GrapevineData.Statistics.Session do
  @moduledoc """
  Web client session Schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias GrapevineData.Games.Game

  @type t :: %__MODULE__{}

  schema "web_client_sessions" do
    field(:sid, Ecto.UUID)

    field(:started_at, :utc_datetime)
    field(:closed_at, :utc_datetime)

    belongs_to(:game, Game)
  end

  def started_changeset(struct, sid, time) do
    struct
    |> change()
    |> put_change(:sid, sid)
    |> put_change(:started_at, DateTime.truncate(time, :second))
  end

  def closed_changeset(struct, time) do
    struct
    |> change()
    |> put_change(:closed_at, DateTime.truncate(time, :second))
  end
end
