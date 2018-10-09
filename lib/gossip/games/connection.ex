defmodule Gossip.Games.Connection do
  @moduledoc """
  Connection Schema
  """

  use Gossip.Schema

  alias Gossip.Games.Game

  @types ["web", "telnet", "secure telnet"]

  schema "connections" do
    field(:type, :string)
    field(:url, :string)
    field(:host, :string)
    field(:port, :integer)

    belongs_to(:game, Game)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:type, :url, :host, :port])
    |> validate_required([:type])
    |> validate_inclusion(:type, @types)
    |> validate_by_type()
  end

  def update_changeset(struct, params) do
    struct
    |> cast(params, [:url, :host, :port])
    |> validate_by_type()
  end

  defp validate_by_type(changeset) do
    case get_field(changeset, :type) do
      "web" ->
        changeset
        |> validate_required([:url])
        |> validate_format(:url, ~r/^https?:\/\/\w+.\w+/)

      "telnet" ->
        changeset
        |> validate_required([:host, :port])
        |> validate_inclusion(:port, 0..65_535)

      "secure telnet" ->
        changeset
        |> validate_required([:host, :port])
        |> validate_inclusion(:port, 0..65_535)
    end
  end
end
