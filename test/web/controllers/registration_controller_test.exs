defmodule Web.RegistrationControllerTest do
  use Web.ConnCase

  describe "registering a new game" do
    test "successful", %{conn: conn} do
      params = %{
        name: "A MUD",
        email: "admin@example.com",
        password: "password",
        password_confirmation: "password",
      }

      conn = post(conn, registration_path(conn, :create), game: params)

      assert redirected_to(conn) == page_path(conn, :index)
    end

    test "failure", %{conn: conn} do
      params = %{
        name: "A MUD",
        email: "admin@example.com",
      }

      conn = post(conn, registration_path(conn, :create), game: params)

      assert html_response(conn, 422)
    end
  end
end
