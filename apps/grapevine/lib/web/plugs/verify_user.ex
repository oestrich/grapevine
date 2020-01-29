defmodule Web.Plugs.VerifyUser do
  @moduledoc """
  Verify a user is in the session
  """

  import Phoenix.Controller

  alias Web.Router.Helpers, as: Routes

  def init(default), do: default

  def call(conn, _opts) do
    case conn.assigns do
      %{current_user: current_user} when current_user != nil ->
        conn

      _ ->
        conn
        |> put_flash(:info, "You must sign in first")
        |> redirect(to: Routes.page_path(conn, :index))
    end
  end
end
