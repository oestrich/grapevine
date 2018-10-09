defmodule Web.ConnectionController do
  use Web, :controller

  plug Web.Plugs.VerifyUser

  alias Gossip.Games

  def create(conn, %{"game_id" => game_id, "connection" => params}) do
    %{current_user: user} = conn.assigns

    with {:ok, game} <- Games.get(user, game_id),
         {:ok, _connection} <- Games.create_connection(game, params) do
      conn
      |> put_flash(:info, "Created the connection!")
      |> redirect(to: user_game_path(conn, :index))
    else
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Coult not create the connection!")
        |> redirect(to: user_game_path(conn, :index))
    end
  end

  def delete(conn, %{"id" => id}) do
    %{current_user: user} = conn.assigns

    with {:ok, connection} <- Games.get_connection(id),
         true <- Games.user_owns_connection?(user, connection),
         {:ok, _connection} <- Games.delete_connection(connection) do
      conn
      |> put_flash(:info, "Created the connection!")
      |> redirect(to: user_game_path(conn, :index))
    else
      _ ->
        conn
        |> put_flash(:error, "Coult not delete the connection!")
        |> redirect(to: user_game_path(conn, :index))
    end
  end
end
