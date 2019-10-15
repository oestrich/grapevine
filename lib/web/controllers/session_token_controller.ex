defmodule Web.SessionTokenController do
  use Web, :controller

  plug(Web.Plugs.SessionToken, api: true)

  def create(conn, _params) do
    conn
    |> put_status(201)
    |> render("token.json")
  end
end
