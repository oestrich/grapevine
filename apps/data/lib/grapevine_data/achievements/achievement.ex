defmodule GrapevineData.Achievements.Achievement do
  @moduledoc """
  Achievement Schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias GrapevineData.Games.Game

  @type t :: %__MODULE__{}

  schema "achievements" do
    field(:key, Ecto.UUID, read_after_writes: true)
    field(:title, :string)
    field(:description, :string)
    field(:display, :boolean, default: true)
    field(:points, :integer, default: 0)
    field(:partial_progress, :boolean, default: false)
    field(:total_progress, :integer)

    belongs_to(:game, Game)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:title, :description, :display, :points, :partial_progress, :total_progress])
    |> validate_required([:title, :display, :points, :partial_progress])
    |> validate_inclusion(:points, 0..100)
    |> validate_total_progress()
    |> foreign_key_constraint(:game_id)
  end

  defp validate_total_progress(changeset) do
    case get_field(changeset, :partial_progress) do
      true ->
        validate_required(changeset, [:total_progress])

      _ ->
        changeset
    end
  end
end
