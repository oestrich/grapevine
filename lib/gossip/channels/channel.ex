defmodule Gossip.Channels.Channel do
  @moduledoc """
  Channel schema
  """

  use Gossip.Schema

  schema "channels" do
    field(:name, :string)
    field(:description, :string)
    field(:hidden, :boolean)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :description])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
