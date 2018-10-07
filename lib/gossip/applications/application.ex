defmodule Gossip.Applications.Application do
  @moduledoc """
  Application Schema
  """

  use Gossip.Schema

  schema "applications" do
    field(:name, :string)
    field(:short_name, :string)
    field(:client_id, Ecto.UUID)
    field(:client_secret, Ecto.UUID)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :short_name])
    |> validate_required([:name, :short_name])
    |> validate_length(:short_name, less_than_or_equal_to: 15)
    |> validate_format(:short_name, ~r/^[a-zA-Z0-9]+$/)
    |> ensure(:client_id, UUID.uuid4())
    |> ensure(:client_secret, UUID.uuid4())
    |> unique_constraint(:name, name: :applications_lower_name_index)
    |> unique_constraint(:short_name, name: :applications_lower_short_name_index)
    |> unique_constraint(:client_id)
  end
end
