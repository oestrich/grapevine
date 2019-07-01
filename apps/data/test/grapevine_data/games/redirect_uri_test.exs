defmodule Grapevine.RedirectURIs.RedirectURITest do
  use ExUnit.Case

  alias GrapevineData.Games.RedirectURI

  describe "uri validations" do
    test "uri must be https" do
      changeset = %RedirectURI{} |> RedirectURI.changeset("https://example.com/")
      refute changeset.errors[:uri]

      changeset = %RedirectURI{} |> RedirectURI.changeset("http://example.com/")
      assert changeset.errors[:uri]
    end

    test "uri can be localhost http" do
      changeset = %RedirectURI{} |> RedirectURI.changeset("http://localhost/")
      refute changeset.errors[:uri]
    end

    test "uri must be a full uri" do
      changeset = %RedirectURI{} |> RedirectURI.changeset("https://example.com/")
      refute changeset.errors[:uri]

      changeset = %RedirectURI{} |> RedirectURI.changeset("https://")
      assert changeset.errors[:uri]
    end

    test "uri must include a path" do
      changeset = %RedirectURI{} |> RedirectURI.changeset("https://example.com/")
      refute changeset.errors[:uri]

      changeset = %RedirectURI{} |> RedirectURI.changeset("https://example.com")
      assert changeset.errors[:uri]
    end

    test "uri must not include a query" do
      changeset = %RedirectURI{} |> RedirectURI.changeset("https://example.com/")
      refute changeset.errors[:uri]

      changeset = %RedirectURI{} |> RedirectURI.changeset("https://example.com/?query")
      assert changeset.errors[:uri]
    end

    test "uri must not include a fragment" do
      changeset = %RedirectURI{} |> RedirectURI.changeset("https://example.com/")
      refute changeset.errors[:uri]

      changeset = %RedirectURI{} |> RedirectURI.changeset("https://example.com/#fragment")
      assert changeset.errors[:uri]
    end
  end
end
