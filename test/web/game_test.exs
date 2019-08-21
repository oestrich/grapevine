defmodule Web.GameTest do
  use ExUnit.Case

  alias Web.Game

  describe "checking if the client is allowed to load" do
    test "anonymous allowed" do
      game = %{allow_anonymous_client: true}

      assert Game.client_allowed?(game, %{}, :user) == {:ok, :allowed}
      assert Game.client_allowed?(game, %{user: %{}}, :user) == {:ok, :allowed}
    end

    test "anonymous not allowed, user is assigned" do
      game = %{allow_anonymous_client: false}
      user = %{id: 1}

      assert Game.client_allowed?(game, %{user: user}, :user) == {:ok, :allowed}
    end

    test "anonymous not allowed, no user" do
      game = %{allow_anonymous_client: false}

      assert Game.client_allowed?(game, %{}, :user) == {:error, :not_signed_in}
    end
  end
end
