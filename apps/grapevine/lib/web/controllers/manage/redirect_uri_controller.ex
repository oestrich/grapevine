defmodule Web.Manage.RedirectURIController do
  use Web, :controller

  plug(Web.Plugs.VerifyUser)

  alias GrapevineData.Games

  def create(conn, %{"game_id" => game_id, "redirect_uri" => %{"uri" => uri}}) do
    %{current_user: user} = conn.assigns

    with {:ok, game} <- Games.get(user, game_id),
         {:ok, connection} <- Games.create_redirect_uri(game, uri) do
      conn
      |> put_flash(:info, "Saved the redirect URI")
      |> redirect(to: manage_game_path(conn, :show, connection.game_id))
    else
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "URI was invalid")
        |> redirect(to: manage_game_path(conn, :show, game_id))
    end
  end

  def delete(conn, %{"id" => id}) do
    %{current_user: user} = conn.assigns

    with {:ok, redirect_uri} <- Games.get_redirect_uri(id),
         true <- Games.user_owns_redirect_uri?(user, redirect_uri),
         {:ok, redirect_uri} <- Games.delete_redirect_uri(redirect_uri) do
      conn
      |> put_flash(:info, "Deleted the URI")
      |> redirect(to: manage_game_path(conn, :show, redirect_uri.game_id))
    else
      _ ->
        conn
        |> put_flash(:error, "Could not delete the URI")
        |> redirect(to: manage_setting_path(conn, :show))
    end
  end
end
