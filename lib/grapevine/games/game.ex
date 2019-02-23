defmodule Grapevine.Games.Game do
  @moduledoc """
  Game Schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Grapevine.Accounts.User
  alias Grapevine.Achievements.Achievement
  alias Grapevine.Events.Event
  alias Grapevine.Games
  alias Grapevine.Games.Connection
  alias Grapevine.Games.RedirectURI
  alias Grapevine.Gauges.Gauge

  @type t :: %__MODULE__{}

  schema "games" do
    field(:name, :string)
    field(:short_name, :string)
    field(:user_agent, :string)
    field(:version, :string, default: "1.0.0")
    field(:display, :boolean, default: true)
    field(:allow_character_registration, :boolean, default: true)
    field(:enable_web_client, :boolean, default: false)
    field(:allow_anonymous_client, :boolean, default: false)

    field(:last_seen_at, :utc_datetime)
    field(:mssp_last_seen_at, :utc_datetime)

    field(:tagline, :string)
    field(:description, :string)
    field(:homepage_url, :string)

    field(:client_id, Ecto.UUID)
    field(:client_secret, Ecto.UUID)

    field(:cover_key, Ecto.UUID)
    field(:cover_extension, :string)

    field(:cname, :string)

    belongs_to(:user, User)

    has_many(:achievements, Achievement)
    has_many(:connections, Connection)
    has_many(:events, Event)
    has_many(:gauges, Gauge)
    has_many(:redirect_uris, RedirectURI)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :name,
      :short_name,
      :homepage_url,
      :tagline,
      :description,
      :display,
      :allow_character_registration,
      :enable_web_client,
      :allow_anonymous_client
    ])
    |> validate_required([
      :name,
      :short_name,
      :display,
      :user_id,
      :display,
      :allow_character_registration,
      :enable_web_client,
      :allow_anonymous_client
    ])
    |> check_name_against_block_list(:name)
    |> check_name_against_block_list(:short_name)
    |> maybe_strip_carriage_returns_from_description()
    |> validate_length(:short_name, max: 15)
    |> validate_length(:tagline, max: 70)
    |> validate_format(:short_name, ~r/^[a-zA-Z0-9]+$/)
    |> validate_format(:homepage_url, ~r/^https?:\/\/.+\./)
    |> Grapevine.Schema.ensure(:client_id, UUID.uuid4())
    |> Grapevine.Schema.ensure(:client_secret, UUID.uuid4())
    |> unique_constraint(:name, name: :games_lower_name_index)
    |> unique_constraint(:short_name, name: :games_lower_short_name_index)
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

  def cover_changeset(struct, key, extension) do
    struct
    |> change()
    |> put_change(:cover_key, key)
    |> put_change(:cover_extension, extension)
  end

  def seen_changeset(struct, seen_at) do
    struct
    |> change()
    |> put_change(:last_seen_at, DateTime.truncate(seen_at, :second))
  end

  def seen_on_mssp_changeset(struct, seen_at) do
    struct
    |> change()
    |> put_change(:mssp_last_seen_at, DateTime.truncate(seen_at, :second))
  end

  defp maybe_strip_carriage_returns_from_description(changeset) do
    case get_change(changeset, :description) do
      nil ->
        changeset

      description ->
        put_change(changeset, :description, String.replace(description, "\r", ""))
    end
  end

  defp check_name_against_block_list(changeset, field) do
    case get_change(changeset, field) do
      nil ->
        changeset

      value ->
        case Enum.member?(Games.name_blocklist(), String.downcase(value)) do
          true ->
            add_error(changeset, field, "is blocked")

          false ->
            changeset
        end
    end
  end
end
