defmodule Gossip.GamesTest do
  use Gossip.DataCase

  alias Gossip.Games

  describe "registering a new game" do
    test "successful" do
      {:ok, game} = Games.register(%{
        name: "A MUD",
        email: "admin@example.com",
        password: "password",
        password_confirmation: "password",
      })

      assert game.name == "A MUD"
      assert game.email == "admin@example.com"
      assert game.password_hash
      assert game.client_id
      assert game.client_secret
    end
  end
end
