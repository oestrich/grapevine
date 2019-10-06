defmodule Web.Manage.ConnectionController do
  use Web, :controller

  plug(Web.Plugs.VerifyUser)

  alias Grapevine.Games

  def create(conn, %{"game_id" => game_id, "connection" => params}) do
    %{current_user: user} = conn.assigns

    with {:ok, game} <- Games.get(user, game_id),
         {:ok, connection} <- Games.create_connection(game, params) do
      conn
      |> put_flash(:info, "Created the connection!")
      |> redirect(to: manage_game_path(conn, :show, connection.game_id))
    else
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Could not create the connection!")
        |> redirect(to: manage_game_path(conn, :show, game_id))
    end
  end

  def edit(conn, %{"id" => id}) do
    %{current_user: user} = conn.assigns

    with {:ok, connection} <- Games.get_connection(id),
         true <- Games.user_owns_connection?(user, connection),
         {:ok, game} <- Games.get(connection.game_id) do
      conn
      |> assign(:game, game)
      |> assign(:connection, connection)
      |> assign(:changeset, Games.edit_connection(connection))
      |> render("edit.html")
    else
      _ ->
        conn
        |> put_flash(:error, "Could not edit the connection!")
        |> redirect(to: manage_setting_path(conn, :show))
    end
  end

  def update(conn, %{"id" => id, "connection" => params}) do
    %{current_user: user} = conn.assigns
    {:ok, connection} = Games.get_connection(id)

    with true <- Games.user_owns_connection?(user, connection),
         {:ok, connection} <- Games.update_connection(connection, params) do
      conn
      |> put_flash(:info, "Updated the connection!")
      |> redirect(to: manage_game_path(conn, :show, connection.game_id))
    else
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Could not update the connection!")
        |> redirect(to: manage_game_path(conn, :show, connection.game_id))
    end
  end

  def delete(conn, %{"id" => id}) do
    %{current_user: user} = conn.assigns

    with {:ok, connection} <- Games.get_connection(id),
         true <- Games.user_owns_connection?(user, connection),
         {:ok, connection} <- Games.delete_connection(connection) do
      conn
      |> put_flash(:info, "Deleted the connection!")
      |> redirect(to: manage_game_path(conn, :show, connection.game_id))
    else
      _ ->
        conn
        |> put_flash(:error, "Could not delete the connection!")
        |> redirect(to: manage_setting_path(conn, :show))
    end
  end
end
