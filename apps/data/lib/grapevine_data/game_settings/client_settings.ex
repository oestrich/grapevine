defmodule GrapevineData.GameSettings.ClientSettings do
  @moduledoc """
  Client settings Schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias GrapevineData.Games.Game

  @type t :: %__MODULE__{}

  schema "client_settings" do
    field(:character_package, :string)
    field(:character_message, :string)
    field(:character_name_path, :string)

    field(:new_environ_enabled, :boolean, default: false)

    belongs_to(:game, Game)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:character_package, :character_message, :character_name_path])
    |> validate_character_message()
  end

  defp validate_character_message(changeset) do
    character_package = get_field(changeset, :character_package)
    character_message = get_field(changeset, :character_message)
    character_name_path = get_field(changeset, :character_name_path)

    case character_package != nil || character_message != nil || character_name_path != nil do
      true ->
        validate_required(changeset, [:character_package, :character_message, :character_name_path])

      false ->
        changeset
    end
  end
end
