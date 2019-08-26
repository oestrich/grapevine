defmodule GrapevineData.Games.ConnectionTest do
  use Grapevine.DataCase

  alias GrapevineData.Games.Connection

  describe "validations" do
    test "cannot use grapevine as a web client" do
      changeset =
        Connection.changeset(%Connection{}, %{
          type: "web",
          url: "http://grapevine.haus/games/play"
        })

      assert Keyword.has_key?(changeset.errors, :url)
    end
  end
end
