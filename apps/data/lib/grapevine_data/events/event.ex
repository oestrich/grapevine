defmodule GrapevineData.Events.Event do
  @moduledoc """
  Event Schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias GrapevineData.Games.Game

  @type t :: %__MODULE__{}

  schema "events" do
    field(:uid, Ecto.UUID, read_after_writes: true)
    field(:title, :string)
    field(:description, :string)
    field(:start_date, :date)
    field(:end_date, :date)

    belongs_to(:game, Game)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:title, :description, :start_date, :end_date])
    |> validate_required([:title, :start_date, :end_date])
    |> validate_start_before_end()
  end

  defp validate_start_before_end(changeset) do
    with start_date when start_date != nil <- get_field(changeset, :start_date),
         end_date when end_date != nil <- get_field(changeset, :end_date) do
      case Timex.before?(start_date, end_date) || start_date == end_date do
        true ->
          changeset

        false ->
          add_error(changeset, :end_date, "must come after the start date")
      end
    else
      _ ->
        changeset
    end
  end
end
