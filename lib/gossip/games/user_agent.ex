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
end
