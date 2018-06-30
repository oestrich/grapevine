defmodule Gossip.Channels.Channel do
  use Gossip.Schema

  schema "channels" do
    field(:name, :string)
    field(:description, :string)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :description])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
