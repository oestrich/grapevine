defmodule GrapevineData.Gauges.Gauge do
  @moduledoc """
  Gauge Schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias GrapevineData.Games.Game

  @type t :: %__MODULE__{}

  @colors ["purple", "red", "green", "blue", "yellow"]

  @derive {Jason.Encoder, only: [:name, :message, :value, :max, :color, :is_docked]}
  schema "gauges" do
    field(:name, :string)
    field(:package, :string)
    field(:message, :string)
    field(:value, :string)
    field(:max, :string)
    field(:color, :string)
    field(:is_docked, :boolean, default: true)

    belongs_to(:game, Game)

    timestamps()
  end

  def colors(), do: @colors

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :package, :message, :value, :max, :color, :is_docked])
    |> validate_required([:name, :package, :message, :value, :max, :color, :is_docked])
    |> validate_inclusion(:color, @colors)
    |> validate_format(:package, ~r/[A-Za-z_][A-Za-z0-9_-]*(?:\.[A-Za-z_][A-Za-z0-9_-]*)* \d+/)
    |> validate_message()
    |> foreign_key_constraint(:game_id)
  end

  defp validate_message(changeset) do
    case changeset.valid? do
      true ->
        package = get_field(changeset, :package)
        message = get_field(changeset, :message)

        package = List.first(String.split(package, " "))

        [_message | message_package] = Enum.reverse(String.split(message, "."))
        message_package = Enum.join(Enum.reverse(message_package), ".")

        case package == message_package do
          true ->
            changeset

          false ->
            add_error(changeset, :message, "must match the package")
        end

      false ->
        changeset
    end
  end
end
