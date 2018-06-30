defmodule Web.Plugs.VerifyGame do
  @moduledoc """
  Verify a game is in the session
  """

  import Phoenix.Controller

  alias Web.Router.Helpers, as: Routes

  def init(default), do: default

  def call(conn, _opts) do
    case conn.assigns do
      %{current_game: current_game} when current_game != nil ->
        conn

      _ ->
        conn
        |> put_flash(:info, "You must sign in first")
        |> redirect(to: Routes.page_path(conn, :index))
    end
  end
end
