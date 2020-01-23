defmodule Web.RegistrationVerifyController do
  use Web, :controller

  alias GrapevineData.Accounts

  def show(conn, %{"token" => token}) do
    case Accounts.verify_email(token) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Your email has been verified. Thanks!")
        |> put_session(:user_token, user.token)
        |> redirect(to: Routes.page_path(conn, :index))

      _ ->
        conn
        |> put_flash(:error, "Something was wrong with your token. Please try again.")
        |> redirect(to: Routes.page_path(conn, :index))
    end
  end
end
