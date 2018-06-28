defmodule Web.Socket.ImplementationTest do
  use Gossip.DataCase

  alias Web.Socket.Implementation

  describe "authenticating" do
    setup do
      %{state: %{status: "inactive"}, game: create_game()}
    end

    test "validating authentication", %{state: state, game: game} do
      frame = %{
        "event" => "authenticate",
        "payload" => %{
          "client-id" => game.client_id,
          "client-secret" => game.client_secret,
        },
      }

      {:ok, response, state} = Implementation.receive(state, frame)

      assert response.status == "success"

      assert state.status == "active"
      assert state.game.id == game.id
    end

    test "invalid credentials", %{state: state, game: game} do
      frame = %{
        "event" => "authenticate",
        "payload" => %{
          "client-id" => game.client_id,
          "client-secret" => "bad",
        },
      }

      {:ok, response, state} = Implementation.receive(state, frame)

      assert response.status == "failure"
      assert state.status == "inactive"
    end
  end
end
