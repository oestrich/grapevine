defmodule GrapevineData.Games.RedirectURI do
  @moduledoc """
  Redirect URI Schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias GrapevineData.Games.Game

  @type t :: %__MODULE__{}

  schema "redirect_uris" do
    field(:uri, :string)

    belongs_to(:game, Game)

    timestamps()
  end

  def changeset(struct, uri) do
    params = %{uri: uri}

    struct
    |> cast(params, [:uri])
    |> validate_required([:uri])
    |> validate_uri()
  end

  defp validate_uri(changeset) do
    case get_field(changeset, :uri) do
      nil ->
        changeset

      uri ->
        uri = URI.parse(uri)

        changeset
        |> validate_uri_scheme(uri)
        |> validate_uri_host(uri)
        |> validate_uri_path(uri)
        |> validate_uri_query(uri)
        |> validate_uri_fragment(uri)
    end
  end

  defp validate_uri_scheme(changeset, uri) do
    case uri.scheme do
      "https" ->
        changeset

      "http" ->
        case uri.host do
          "localhost" ->
            changeset

          _ ->
            add_error(changeset, :uri, "must be https")
        end

      _ ->
        add_error(changeset, :uri, "must be https")
    end
  end

  defp validate_uri_host(changeset, uri) do
    case uri.host do
      nil ->
        add_error(changeset, :uri, "must be a fully qualified URI")

      _ ->
        changeset
    end
  end

  defp validate_uri_path(changeset, uri) do
    case uri.path do
      nil ->
        add_error(changeset, :uri, "must be a fully qualified URI")

      _ ->
        changeset
    end
  end

  defp validate_uri_query(changeset, uri) do
    case uri.query do
      nil ->
        changeset

      _ ->
        add_error(changeset, :uri, "must be a fully qualified URI")
    end
  end

  defp validate_uri_fragment(changeset, uri) do
    case uri.fragment do
      nil ->
        changeset

      _ ->
        add_error(changeset, :uri, "must be a fully qualified URI")
    end
  end
end
