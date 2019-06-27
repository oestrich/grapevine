defmodule Web.Plugs.EnsureUserVerified do
  @moduledoc """
  Verify a user is in the session
  """

  import Plug.Conn
  import Phoenix.Controller

  alias GrapevineData.Accounts
  alias Web.Router.Helpers, as: Routes

  def init(default), do: default

  def call(conn, _opts) do
    %{current_user: user} = conn.assigns

    case Accounts.email_verified?(user) do
      true ->
        conn

      false ->
        conn
        |> put_flash(:error, "You must verify your email first.")
        |> redirect(to: Routes.page_path(conn, :index))
        |> halt()
    end
  end
end
