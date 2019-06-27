defmodule GrapevineData.AuthorizationsTest do
  use Grapevine.DataCase

  alias GrapevineData.Authorizations
  alias GrapevineData.Authorizations.AccessToken
  alias GrapevineData.Authorizations.Authorization
  alias GrapevineData.Games

  describe "starting to authenticate" do
    setup [:with_user, :with_game]

     test "successful", %{user: user, game: game} do
      {:ok, authorization} = Authorizations.start_auth(user, game, %{
        "state" => "my+state",
        "redirect_uri" => "https://example.com/oauth/callback",
        "scope" => "profile"
      })

      assert authorization.state == "my+state"
      assert authorization.redirect_uri == "https://example.com/oauth/callback"
      assert authorization.scopes == ["profile"]
    end

    test "reuses authorizations if one is already active", %{user: user, game: game} do
      authorization = create_authorization(user, game)

      {:ok, new_authorization} = Authorizations.start_auth(user, game, %{
        "state" => "my+state",
        "redirect_uri" => "https://example.com/oauth/callback",
        "scope" => "profile"
      })

      assert new_authorization.id == authorization.id
    end

    test "regenerates the authorization's code on reuse", %{user: user, game: game} do
      authorization = create_authorization(user, game)

      {:ok, _authorization} = Authorizations.mark_as_used(authorization)

      {:ok, new_authorization} = Authorizations.start_auth(user, game, %{
        "state" => "my+state",
        "redirect_uri" => "https://example.com/oauth/callback",
        "scope" => "profile"
      })

      assert new_authorization.code
    end

    test "deactivates all previous tokens on reuse", %{user: user, game: game} do
      authorization = create_authorization(user, game)

      {:ok, access_token} = Authorizations.create_token(game.client_id, authorization.redirect_uri, authorization.code)

      {:ok, _new_authorization} = Authorizations.start_auth(user, game, %{
        "state" => "my+state",
        "redirect_uri" => "https://example.com/oauth/callback",
        "scope" => "profile"
      })

      access_token = Repo.get(AccessToken, access_token.id)
      refute access_token.active
    end

    test "does not reuse if scopes are different", %{user: user, game: game} do
      authorization = create_authorization(user, game)

      {:ok, new_authorization} = Authorizations.start_auth(user, game, %{
        "state" => "my+state",
        "redirect_uri" => "https://example.com/oauth/callback",
        "scope" => "profile email"
      })

      assert new_authorization.id != authorization.id
    end

    test "invalid if redirect uri does not match a known uri", %{user: user, game: game} do
      {:error, changeset} = Authorizations.start_auth(user, game, %{
        "state" => "my+state",
        "redirect_uri" => "https://example.com/oauth/callbacks",
        "scope" => "profile"
      })

      assert changeset.errors[:redirect_uri]
    end

    test "missing params", %{user: user, game: game} do
      {:error, changeset} = Authorizations.start_auth(user, game, %{
        "state" => "my+state",
      })

      assert changeset.errors[:redirect_uri]
    end
  end

  describe "get a user's authorization" do
    setup [:with_user, :with_game]

    test "scoped to the user", %{user: user, game: game} do
      authorization = create_authorization(user, game)

      assert {:ok, _authorization} = Authorizations.get(user, authorization.id)

      user = create_user(%{username: "other", email: "other@example.com"})
      assert {:error, :not_found} = Authorizations.get(user, authorization.id)
    end
  end

  describe "mark an authorization as allowed" do
    setup [:with_user, :with_game]

    test "sets authorization to active", %{user: user, game: game} do
      authorization = create_authorization(user, game)

      {:ok, authorization} = Authorizations.authorize(authorization)

      assert authorization.active
    end
  end

  describe "mark an authorization as denied" do
    setup [:with_user, :with_game]

    test "deletes the authorization", %{user: user, game: game} do
      authorization = create_authorization(user, game)

      {:ok, authorization} = Authorizations.deny(authorization)

      assert {:error, :not_found} = Authorizations.get(user, authorization.id)
    end
  end

  describe "redirect uris" do
    test "authorized uri" do
      authorization = %Authorization{
        code: "code",
        redirect_uri: "https://example.com/oauth/callback",
        state: "my+state"
      }

      {:ok, uri} = Authorizations.authorized_redirect_uri(authorization)
      assert uri == "https://example.com/oauth/callback?code=code&state=my%2Bstate"
    end

    test "denied uri" do
      authorization = %Authorization{
        code: "code",
        redirect_uri: "https://example.com/oauth/callback",
        state: "my+state"
      }

      {:ok, uri} = Authorizations.denied_redirect_uri(authorization)
      assert uri == "https://example.com/oauth/callback?error=access_denied&state=my%2Bstate"
    end
  end

  describe "create an access token for an authorization" do
    setup [:with_user, :with_game]

    test "create a token", %{user: user, game: game} do
      authorization = create_authorization(user, game)

      {:ok, access_token} = Authorizations.create_token(game.client_id, authorization.redirect_uri, authorization.code)

      assert access_token.access_token
    end

    test "authorization code is good once", %{user: user, game: game} do
      authorization = create_authorization(user, game)

      {:ok, _access_token} = Authorizations.create_token(game.client_id, authorization.redirect_uri, authorization.code)
      {:error, :invalid_grant} = Authorizations.create_token(game.client_id, authorization.redirect_uri, authorization.code)
    end

    test "authorization is not active", %{user: user, game: game} do
      {:ok, authorization} = Authorizations.start_auth(user, game, %{
        "state" => "my+state",
        "redirect_uri" => "https://example.com/oauth/callback",
        "scope" => "profile",
      })

      {:error, :invalid_grant} = Authorizations.create_token(game.client_id, authorization.redirect_uri, authorization.code)
    end

    test "invalid client id", %{user: user, game: game} do
      authorization = create_authorization(user, game)

      {:error, :invalid_grant} = Authorizations.create_token("invalid", authorization.redirect_uri, authorization.code)
    end

    test "invalid redirect uri", %{user: user, game: game} do
      authorization = create_authorization(user, game)

      {:error, :invalid_grant} = Authorizations.create_token(game.client_id, "redirect", authorization.code)
    end

    test "invalid code", %{user: user, game: game} do
      authorization = create_authorization(user, game)

      {:error, :invalid_grant} = Authorizations.create_token(game.client_id, authorization.redirect_uri, "code")
    end
  end

  describe "access token is valid" do
    setup [:with_user, :with_game, :with_token]

    test "is valid", %{access_token: access_token} do
      assert Authorizations.valid_token?(access_token)
    end

    test "token is not active", %{access_token: access_token} do
      access_token = %{access_token | active: false}
      refute Authorizations.valid_token?(access_token)
    end

    test "after expiration", %{access_token: access_token} do
      yesterday = Timex.now() |> Timex.shift(minutes: -70)
      access_token = %{access_token | inserted_at: yesterday}

      refute Authorizations.valid_token?(access_token)
    end

    test "authorization is not valid", %{authorization: authorization, access_token: access_token} do
      authorization
      |> Ecto.Changeset.change(%{active: false})
      |> Repo.update!()

      refute Authorizations.valid_token?(access_token)
    end
  end

  def with_user(_) do
    %{user: create_user()}
  end

  def with_game(_) do
    game = create_game(create_user(%{username: "owner", email: "owner@example.com"}))
    Games.create_redirect_uri(game, "https://example.com/oauth/callback")

    game = Repo.preload(game, [:redirect_uris])
    %{game: game}
  end

  def with_token(%{user: user, game: game}) do
    {:ok, authorization} = Authorizations.start_auth(user, game, %{
      "state" => "my+state",
      "redirect_uri" => "https://example.com/oauth/callback",
      "scope" => "profile",
    })

    {:ok, authorization} = Authorizations.authorize(authorization)
    {:ok, access_token} = Authorizations.create_token(authorization)

    %{authorization: authorization, access_token: access_token}
  end
end
