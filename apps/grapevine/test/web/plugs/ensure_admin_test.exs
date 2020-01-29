defmodule Web.Plugs.EnsureAdminTest do
  use Web.ConnCase

  alias Web.Plugs.EnsureAdmin

  describe "verifies the user is an admin" do
    test "is an admin", %{conn: conn} do
      user = TestHelpers.user_struct(%{role: "admin"})

      conn =
        conn
        |> assign(:current_user, user)
        |> bypass_through()
        |> get("/admin")
        |> EnsureAdmin.call([])

      refute conn.halted
    end

    test "not an admin", %{conn: conn} do
      user = TestHelpers.user_struct()

      conn =
        conn
        |> assign(:current_user, user)
        |> bypass_through(Web.Router, [:browser])
        |> get("/admin")
        |> EnsureAdmin.call([])

      assert conn.halted
    end
  end
end
