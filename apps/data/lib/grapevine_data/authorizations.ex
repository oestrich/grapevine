defmodule GrapevineData.Authorizations do
  @moduledoc """
  Authorize remote logins
  """

  import Ecto.Query

  alias GrapevineData.Authorizations.AccessToken
  alias GrapevineData.Authorizations.Authorization
  alias GrapevineData.Games
  alias GrapevineData.Repo

  @doc """
  Check for a username before allowing oauth to proceed
  """
  def check_for_username(user) do
    case is_nil(user.username) do
      true ->
        {:error, :no_username}

      false ->
        {:ok, user}
    end
  end

  @doc """
  Start authorization

  Creates an authorization record
  """
  def start_auth(user, game, params) do
    :telemetry.execute([:web, :oauth, :start], %{count: 1}, %{user_id: user.id, game_id: game.id})

    case Map.fetch(params, "redirect_uri") do
      {:ok, redirect_uri} ->
        scopes =
          params
          |> Map.get("scope", "")
          |> String.split(" ")
          |> Enum.sort()

        params = Map.put(params, "scopes", scopes)

        opts = [
          user_id: user.id,
          game_id: game.id,
          redirect_uri: redirect_uri,
          active: true,
          scopes: scopes,
        ]

        case Repo.get_by(Authorization, opts) do
          nil ->
            create_authorization(user, game, params)

          authorization ->
            refresh_code(authorization)
        end

      _ ->
        create_authorization(user, game, params)
    end
  end

  defp refresh_code(authorization) do
    changeset = authorization |> Authorization.refresh_code_changeset()

    case Repo.update(changeset) do
      {:ok, authorization} ->
        deactivate_all_tokens(authorization)
        {:ok, authorization}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp deactivate_all_tokens(authorization) do
    AccessToken
    |> where([at], at.authorization_id == ^authorization.id)
    |> Repo.update_all(set: [active: false])
  end

  defp create_authorization(user, game, params) do
    user
    |> Ecto.build_assoc(:authorizations)
    |> Authorization.create_changeset(game, params)
    |> Repo.insert()
  end

  @doc """
  Get a user's authorization record
  """
  def get(user, id) do
    case Repo.get_by(Authorization, user_id: user.id, id: id) do
      nil ->
        {:error, :not_found}

      authorization ->
        {:ok, authorization}
    end
  end

  def get_token(token) do
    case Ecto.UUID.cast(token) do
      {:ok, token} ->
        case Repo.get_by(AccessToken, access_token: token) do
          nil ->
            {:error, :not_found}

          access_token ->
            {:ok, Repo.preload(access_token, [authorization: [:user]])}
        end

      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  Authorize an authorization

  Marks it as active
  """
  def authorize(authorization) do
    :telemetry.execute([:web, :oauth, :authorized], %{count: 1}, %{user_id: authorization.user_id, game_id: authorization.game_id})

    authorization
    |> Authorization.authorize_changeset()
    |> Repo.update()
  end

  @doc """
  Deny an authorization

  Deletes the authorization record
  """
  def deny(authorization) do
    :telemetry.execute([:web, :oauth, :denied], %{count: 1}, %{user_id: authorization.user_id, game_id: authorization.game_id})

    Repo.delete(authorization)
  end

  @doc """
  Get an authorized redirect uri

  Includes the authorization code
  """
  def authorized_redirect_uri(authorization) do
    uri = URI.parse(authorization.redirect_uri)
    query = URI.encode_query(%{code: authorization.code, state: authorization.state})
    uri = %{uri | query: query}
    {:ok, URI.to_string(uri)}
  end

  @doc """
  Get a denied redirect uri
  """
  def denied_redirect_uri(authorization) do
    uri = URI.parse(authorization.redirect_uri)
    query = URI.encode_query(%{error: :access_denied, state: authorization.state})
    uri = %{uri | query: query}
    {:ok, URI.to_string(uri)}
  end

  @doc """
  Create an access token
  """
  def create_token(client_id, redirect_uri, code) do
    with {:ok, client_id} <- Ecto.UUID.cast(client_id),
         {:ok, game} <- Games.get_by(client_id: client_id),
         {:ok, code} <- Ecto.UUID.cast(code) do
      case Repo.get_by(Authorization, game_id: game.id, redirect_uri: redirect_uri, code: code, active: true) do
        nil ->
          :telemetry.execute([:web, :oauth, :invalid_grant], %{count: 1}, %{client_id: client_id})

          {:error, :invalid_grant}

        authorization ->
          :telemetry.execute([:web, :oauth, :create_token], %{count: 1}, %{user_id: authorization.user_id, game_id: authorization.game_id})

          create_token(authorization)
      end
    else
      _ ->
        {:error, :invalid_grant}
    end
  end

  @doc false
  def create_token(authorization = %Authorization{}) do
    with {:ok, authorization} <- mark_as_used(authorization) do
      authorization
      |> Ecto.build_assoc(:access_tokens)
      |> AccessToken.create_changeset()
      |> Repo.insert()
    end
  end

  @doc false
  def mark_as_used(authorization) do
    authorization
    |> Authorization.used_changeset()
    |> Repo.update()
  end

  @doc """
  Validate a token

  A token is valid if:
  - within expiration time
  - authorization is active
  """
  def valid_token?(access_token) do
    access_token = Repo.preload(access_token, [:authorization])

    case access_token.authorization.active do
      false ->
        false

      true ->
        valid_til = access_token.inserted_at |> Timex.shift(seconds: access_token.expires_in)
        access_token.active && Timex.before?(Timex.now(), valid_til)
    end
  end
end
