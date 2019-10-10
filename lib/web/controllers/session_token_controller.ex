defmodule Web.SessionTokenController do
  use Web, :controller

  def create(conn = %{assigns: %{session_token: token}}, _params) do
    conn
    |> put_status(201)
    |> json(%{session_token: token})
  end
end
