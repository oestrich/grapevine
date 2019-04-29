defmodule Web.RegistrationControllerTest do
  use Web.ConnCase

  describe "registering a new game" do
    test "successful", %{conn: conn} do
      params = %{
        username: "adminuser",
        email: "admin@example.com",
        password: "password",
        password_confirmation: "password"
      }

      conn = post(conn, Routes.registration_path(conn, :create), user: params)

      assert redirected_to(conn) == Routes.registration_path(conn, :finalize)
    end

    test "failure", %{conn: conn} do
      params = %{
        email: "admin@example.com"
      }

      conn = post(conn, Routes.registration_path(conn, :create), user: params)

      assert html_response(conn, 422)
    end
  end
end
