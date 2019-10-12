defmodule Web.SessionTokenControllerTest do
  use Web.ConnCase

  describe "POST /session_tokens" do
    test "a session token is returned", %{conn: conn} do
      conn = post(conn, Routes.session_token_path(Web.Endpoint, :create))
      assert %{"token" => token} = json_response(conn, 201)

      assert {:ok, uuid} =
               Phoenix.Token.verify(Web.Endpoint, "session token", token, max_age: 86_400)

      assert UUID.info!(uuid)
    end
  end
end
