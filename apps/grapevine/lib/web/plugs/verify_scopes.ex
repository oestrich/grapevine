defmodule Web.Plugs.VerifyScopes do
  @moduledoc """
  Verify the user has appropriate scopes before requesting the accessed resource
  """

  import Plug.Conn
  import Phoenix.Controller

  alias Web.ErrorView

  def init(default), do: default

  def call(conn, opts) do
    scope = Keyword.get(opts, :scope)

    case scope in conn.assigns.current_scopes do
      true ->
        conn

      false ->
        conn
        |> put_status(401)
        |> put_view(ErrorView)
        |> render("401.json")
        |> halt()
    end
  end
end
