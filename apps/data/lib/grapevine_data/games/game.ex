defmodule GrapevineData.Games.Game do
  @moduledoc """
  Game Schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias GrapevineData.Accounts.User
  alias GrapevineData.Achievements.Achievement
  alias GrapevineData.Events.Event
  alias GrapevineData.Games
  alias GrapevineData.Games.Connection
  alias GrapevineData.Games.RedirectURI
  alias GrapevineData.GameSettings.ClientSettings
  alias GrapevineData.GameSettings.HostedSettings
  alias GrapevineData.Gauges.Gauge
  alias GrapevineData.Statistics.Session

  @type t :: %__MODULE__{}

  schema "games" do
    field(:name, :string)
    field(:short_name, :string)
    field(:user_agent, :string)
    field(:version, :string, default: "1.0.0")
    field(:display, :boolean, default: true)
    field(:display_players, :boolean, default: true)
    field(:allow_character_registration, :boolean, default: true)
    field(:enable_web_client, :boolean, default: false)
    field(:allow_anonymous_client, :boolean, default: false)
    field(:featured_order, :integer)
    field(:send_connection_failure_alerts, :boolean, default: false)

    field(:last_seen_at, :utc_datetime)
    field(:telnet_last_seen_at, :utc_datetime)
    field(:display_player_graph, :boolean, default: false)
    field(:featurable, :boolean)

    field(:tagline, :string)
    field(:description, :string)
    field(:homepage_url, :string)
    field(:discord_invite_url, :string)
    field(:twitter_username, :string)

    field(:client_id, Ecto.UUID)
    field(:client_secret, Ecto.UUID)

    field(:cover_key, Ecto.UUID)
    field(:cover_extension, :string)

    field(:hero_key, Ecto.UUID)
    field(:hero_extension, :string)

    field(:site_cname, :string)
    field(:client_cname, :string)

    belongs_to(:user, User)

    has_one(:client_settings, ClientSettings)
    has_one(:hosted_settings, HostedSettings)

    has_many(:achievements, Achievement)
    has_many(:connections, Connection)
    has_many(:events, Event)
    has_many(:gauges, Gauge)
    has_many(:redirect_uris, RedirectURI)
    has_many(:sessions, Session)

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
      :display_players,
      :allow_character_registration,
      :enable_web_client,
      :allow_anonymous_client,
      :discord_invite_url,
      :twitter_username,
      :send_connection_failure_alerts
    ])
    |> validate_required([
      :name,
      :short_name,
      :description,
      :display,
      :display_players,
      :user_id,
      :allow_character_registration,
      :enable_web_client,
      :allow_anonymous_client,
      :send_connection_failure_alerts
    ])
    |> check_name_against_block_list(:name)
    |> check_name_against_block_list(:short_name)
    |> maybe_strip_carriage_returns_from_description()
    |> validate_length(:short_name, max: 15)
    |> validate_length(:tagline, max: 70)
    |> validate_format(:short_name, ~r/^[a-zA-Z0-9]+$/)
    |> validate_format(:homepage_url, ~r/^https?:\/\/.+\./)
    |> validate_format(:discord_invite_url, ~r/^https:\/\/discord.gg\//, message: "should start with https://discord.gg/")
    |> GrapevineData.Schema.ensure(:client_id, UUID.uuid4())
    |> GrapevineData.Schema.ensure(:client_secret, UUID.uuid4())
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

  def hero_changeset(struct, key, extension) do
    struct
    |> change()
    |> put_change(:hero_key, key)
    |> put_change(:hero_extension, extension)
  end

  def seen_changeset(struct, seen_at) do
    struct
    |> change()
    |> put_change(:last_seen_at, DateTime.truncate(seen_at, :second))
    |> put_change(:display_player_graph, true)
  end

  def seen_on_telnet_changeset(struct, seen_at) do
    struct
    |> change()
    |> put_change(:telnet_last_seen_at, DateTime.truncate(seen_at, :second))
  end

  def graph_changeset(struct, display_player_graph) do
    struct
    |> change()
    |> put_change(:display_player_graph, display_player_graph)
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
