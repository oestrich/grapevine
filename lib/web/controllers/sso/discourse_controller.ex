defmodule Web.SSO.DiscourseController do
  use Web, :controller

  alias Discourse.SSO

  def new(conn, %{"sso" => params, "sig" => signature}) do
    %{current_user: user} = conn.assigns

    case SSO.validate(params, signature) do
      {:ok, nonce} ->
        url = SSO.sign_url(user.id, user.email, nonce, username: user.username)
        redirect(conn, external: url)

      _ ->
        conn
        |> put_flash(:error, "Invalid SSO")
        |> redirect(to: Routes.page_path(conn, :index))
    end
  end
end
