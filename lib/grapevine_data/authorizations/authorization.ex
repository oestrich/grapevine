defmodule GrapevineData.Authorizations.Authorization do
  @moduledoc """
  Authorization schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias GrapevineData.Accounts.User
  alias GrapevineData.Authorizations.AccessToken
  alias GrapevineData.Games.Game

  @type t :: %__MODULE__{}

  @scopes ["profile", "email"]

  schema "authorizations" do
    field(:redirect_uri, :string)
    field(:state, :string)
    field(:scopes, {:array, :string}, default: [])
    field(:code, Ecto.UUID)
    field(:active, :boolean, default: false)

    belongs_to(:user, User)
    belongs_to(:game, Game)

    has_many(:access_tokens, AccessToken)

    timestamps()
  end

  def create_changeset(struct, game, params) do
    struct
    |> cast(params, [:redirect_uri, :state, :scopes])
    |> validate_required([:redirect_uri, :state, :scopes])
    |> validate_redirect_uri()
    |> validate_redirect_uri_known(game)
    |> validate_scopes()
    |> put_change(:game_id, game.id)
    |> put_change(:code, UUID.uuid4())
  end

  def authorize_changeset(struct) do
    struct
    |> change()
    |> put_change(:active, true)
  end

  def used_changeset(struct) do
    struct
    |> change()
    |> put_change(:code, nil)
  end

  def refresh_code_changeset(struct) do
    struct
    |> change()
    |> put_change(:code, UUID.uuid4())
  end

  defp validate_scopes(changeset) do
    case get_field(changeset, :scopes) do
      [] ->
        add_error(changeset, :scopes, "must be provided")

      scopes ->
        case Enum.all?(scopes, &Enum.member?(@scopes, &1)) do
          true ->
            changeset

          false ->
            add_error(changeset, :scopes, "are invalid")
        end
    end
  end

  defp validate_redirect_uri(changeset) do
    case get_field(changeset, :redirect_uri) do
      nil ->
        changeset

      "urn:ietf:wg:oauth:2.0:oob" ->
        changeset

      redirect_uri ->
        uri = URI.parse(redirect_uri)

        changeset
        |> validate_redirect_uri_scheme(uri)
        |> validate_redirect_uri_host(uri)
        |> validate_redirect_uri_path(uri)
        |> validate_redirect_uri_query(uri)
        |> validate_redirect_uri_fragment(uri)
    end
  end

  defp validate_redirect_uri_scheme(changeset, uri) do
    case uri.scheme do
      "https" ->
        changeset

      "http" ->
        case uri.host do
          "localhost" ->
            changeset

          _ ->
            add_error(changeset, :redirect_uri, "must be https")
        end

      _ ->
        add_error(changeset, :redirect_uri, "must be https")
    end
  end

  defp validate_redirect_uri_host(changeset, uri) do
    case uri.host do
      nil ->
        add_error(changeset, :redirect_uri, "must be a fully qualified URI")

      _ ->
        changeset
    end
  end

  defp validate_redirect_uri_path(changeset, uri) do
    case uri.path do
      nil ->
        add_error(changeset, :redirect_uri, "must be a fully qualified URI")

      _ ->
        changeset
    end
  end

  defp validate_redirect_uri_query(changeset, uri) do
    case uri.query do
      nil ->
        changeset

      _ ->
        add_error(changeset, :redirect_uri, "must be a fully qualified URI")
    end
  end

  defp validate_redirect_uri_fragment(changeset, uri) do
    case uri.fragment do
      nil ->
        changeset

      _ ->
        add_error(changeset, :redirect_uri, "must be a fully qualified URI")
    end
  end

  defp validate_redirect_uri_known(changeset, game) do
    case get_field(changeset, :redirect_uri) do
      nil ->
        changeset

      "urn:ietf:wg:oauth:2.0:oob" ->
        changeset

      redirect_uri ->
        redirect_uris = Enum.map(game.redirect_uris, &(&1.uri))

        case redirect_uri in redirect_uris do
          true ->
            changeset

          false ->
            add_error(changeset, :redirect_uri, "does not match a know URI")
        end
    end
  end
end
