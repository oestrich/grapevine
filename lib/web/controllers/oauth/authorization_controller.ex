defmodule Web.Oauth.AuthorizationController do
  use Web, :controller

  plug(Web.Plugs.FetchGame when action in [:new])

  alias GrapevineData.Authorizations

  def new(conn, params) do
    %{current_user: user} = conn.assigns

    with %{client_game: game} <- conn.assigns,
         {:ok, user} <- Authorizations.check_for_username(user),
         {:ok, authorization} <- Authorizations.start_auth(user, game, params) do
      case authorization.active do
        true ->
          {:ok, uri} = Authorizations.authorized_redirect_uri(authorization)
          conn |> redirect(external: uri)

        false ->
          conn
          |> assign(:authorization, authorization)
          |> render("new.html")
      end
    else
      {:error, :no_username} ->
        conn
        |> put_flash(:error, "You must set your username before being able to use OAuth.")
        |> redirect(to: manage_setting_path(conn, :show))

      _ ->
        conn
        |> put_flash(:error, "Unknown issue authenticating. Please try again")
        |> redirect(to: page_path(conn, :index))
    end
  end

  def update(conn, %{"authorization" => %{"id" => id, "allow" => "true"}}) do
    %{current_user: user} = conn.assigns

    with {:ok, authorization} <- Authorizations.get(user, id),
         {:ok, authorization} <- Authorizations.authorize(authorization),
         {:ok, uri} <- Authorizations.authorized_redirect_uri(authorization) do
      conn |> redirect(external: uri)
    else
      _ ->
        conn
        |> put_flash(:error, "Unknown issue authenticating. Please try again")
        |> redirect(to: page_path(conn, :index))
    end
  end

  def update(conn, %{"authorization" => %{"id" => id, "allow" => "false"}}) do
    %{current_user: user} = conn.assigns

    with {:ok, authorization} <- Authorizations.get(user, id),
         {:ok, uri} <- Authorizations.denied_redirect_uri(authorization),
         {:ok, _authorization} <- Authorizations.deny(authorization) do
      conn |> redirect(external: uri)
    else
      _ ->
        conn
        |> put_flash(:error, "Unknown issue authenticating. Please try again")
        |> redirect(to: page_path(conn, :index))
    end
  end
end
