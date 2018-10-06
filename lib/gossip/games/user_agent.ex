defmodule Gossip.Games.UserAgent do
  @moduledoc """
  Game Schema
  """

  use Gossip.Schema

  schema "user_agents" do
    field(:version, :string)
    field(:repo_url, :string)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:version])
    |> validate_required([:version])
  end

  def regenerate_changeset(struct) do
    struct
    |> change()
    |> put_change(:client_id, UUID.uuid4())
    |> put_change(:client_secret, UUID.uuid4())
  end

  def metadata_changeset(struct, params) do
    cast(struct, params, [:user_agent, :version])
  end
end
