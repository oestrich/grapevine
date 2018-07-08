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
    |> validate_format(:name, ~r/^[a-zA-Z]+$/)
    |> validate_length(:name, max: 15)
    |> unique_constraint(:name)
  end
end
