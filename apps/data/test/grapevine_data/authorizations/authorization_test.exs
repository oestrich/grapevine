defmodule GrapevineData.Authorizations.AuthorizationTest do
  use ExUnit.Case

  alias GrapevineData.Authorizations.Authorization
  alias GrapevineData.Games.Game

  describe "redirect_uri validations" do
    setup [:with_game]

    test "redirect_uri can be urn:ietf:wg:oauth:2.0:oob", %{game: game} do
      changeset = %Authorization{} |> Authorization.create_changeset(game, %{redirect_uri: "urn:ietf:wg:oauth:2.0:oob"})
      refute changeset.errors[:redirect_uri]
    end

    test "redirect_uri must be https", %{game: game} do
      changeset = %Authorization{} |> Authorization.create_changeset(game, %{redirect_uri: "https://example.com/"})
      refute changeset.errors[:redirect_uri]

      changeset = %Authorization{} |> Authorization.create_changeset(game, %{redirect_uri: "http://example.com/"})
      assert changeset.errors[:redirect_uri]
    end

    test "redirect_uri can be localhost http", %{game: game} do
      changeset = %Authorization{} |> Authorization.create_changeset(game, %{redirect_uri: "http://localhost/"})
      refute changeset.errors[:redirect_uri]
    end

    test "redirect_uri must be a full uri", %{game: game} do
      changeset = %Authorization{} |> Authorization.create_changeset(game, %{redirect_uri: "https://example.com/"})
      refute changeset.errors[:redirect_uri]

      changeset = %Authorization{} |> Authorization.create_changeset(game, %{redirect_uri: "https://"})
      assert changeset.errors[:redirect_uri]
    end

    test "redirect_uri must include a path", %{game: game} do
      changeset = %Authorization{} |> Authorization.create_changeset(game, %{redirect_uri: "https://example.com/"})
      refute changeset.errors[:redirect_uri]

      changeset = %Authorization{} |> Authorization.create_changeset(game, %{redirect_uri: "https://example.com"})
      assert changeset.errors[:redirect_uri]
    end

    test "redirect_uri must not include a query", %{game: game} do
      changeset = %Authorization{} |> Authorization.create_changeset(game, %{redirect_uri: "https://example.com/"})
      refute changeset.errors[:redirect_uri]

      changeset = %Authorization{} |> Authorization.create_changeset(game, %{redirect_uri: "https://example.com/?query"})
      assert changeset.errors[:redirect_uri]
    end

    test "redirect_uri must not include a fragment", %{game: game} do
      changeset = %Authorization{} |> Authorization.create_changeset(game, %{redirect_uri: "https://example.com/"})
      refute changeset.errors[:redirect_uri]

      changeset = %Authorization{} |> Authorization.create_changeset(game, %{redirect_uri: "https://example.com/#fragment"})
      assert changeset.errors[:redirect_uri]
    end
  end

  describe "scope validations " do
    test "must be present" do
      changeset = %Authorization{} |> Authorization.create_changeset(%Game{}, %{scopes: ["profile"]})
      refute changeset.errors[:scopes]

      changeset = %Authorization{} |> Authorization.create_changeset(%Game{}, %{scopes: []})
      assert changeset.errors[:scopes]

      changeset = %Authorization{} |> Authorization.create_changeset(%Game{}, %{scopes: nil})
      assert changeset.errors[:scopes]
    end
  end

  def with_game(_) do
    # faking this list for all test examples above, so the examples above are why its failing
    game = %Game{
      redirect_uris: [
        %{uri: "https://example.com/"},
        %{uri: "http://example.com"},
        %{uri: "https://"},
        %{uri: "https://example.com"},
        %{uri: "https://example.com/?query"},
        %{uri: "https://example.com/#fragment"},
        %{uri: "http://localhost/"},
      ]
    }

    %{game: game}
  end
end
