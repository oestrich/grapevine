defmodule Gossip.Versions.Version do
  @moduledoc """
  Game Schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  @actions ["create", "update", "delete"]
  @schemas ["channels", "games", "events"]

  @type t :: %__MODULE__{}

  schema "versions" do
    field(:action, :string)
    field(:schema, :string)
    field(:schema_id, :integer)
    field(:payload, :map)
    field(:logged_at, :utc_datetime)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:action, :schema, :schema_id, :payload, :logged_at])
    |> validate_required([:action, :schema, :schema_id, :payload, :logged_at])
    |> validate_inclusion(:action, @actions)
    |> validate_inclusion(:schema, @schemas)
  end
end
