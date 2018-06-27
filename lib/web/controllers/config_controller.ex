defmodule Web.ConfigController do
  use Web, :controller

  plug :verify_game

  def show(conn, _params) do
    render(conn, "show.html")
  end

  defp verify_game(conn, _opts) do
    case conn.assigns do
      %{current_game: current_game} when current_game != nil ->
        conn

      _ ->
        conn
        |> put_flash(:info, "You must sign in first")
        |> redirect(to: page_path(conn, :index))
    end
  end
end
