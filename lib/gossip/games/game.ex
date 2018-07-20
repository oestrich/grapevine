defmodule Gossip.Games.Game do
  @moduledoc """
  Game Schema
  """

  use Gossip.Schema

  alias Gossip.Accounts.User

  schema "games" do
    field(:name, :string)
    field(:short_name, :string)
    field(:short_name_downcase, :string)
    field(:user_agent, :string)
    field(:version, :string, default: "1.0.0")
    field(:homepage_url, :string)
    field(:display, :boolean, default: true)

    field(:client_id, Ecto.UUID)
    field(:client_secret, Ecto.UUID)

    belongs_to(:user, User)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :short_name, :homepage_url, :display])
    |> validate_required([:name, :short_name, :display, :user_id])
    |> validate_length(:short_name, less_than_or_equal_to: 15)
    |> validate_format(:short_name, ~r/^[a-zA-Z0-9]+$/)
    |> validate_format(:homepage_url, ~r/^https?:\/\/\w+\./)
    |> update_short_name_downcase()
    |> ensure(:client_id, UUID.uuid4())
    |> ensure(:client_secret, UUID.uuid4())
    |> unique_constraint(:name)
    |> unique_constraint(:short_name, name: :games_short_name_downcase_index)
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

  defp update_short_name_downcase(changeset) do
    case get_field(changeset, :short_name) do
      nil ->
        changeset

      name ->
        put_change(changeset, :short_name_downcase, String.downcase(name))
    end
  end
end
