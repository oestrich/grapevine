defmodule Web.Client.PageController do
  use Web, :controller

  alias Web.ClientRouter.Helpers, as: Routes

  action_fallback(Web.FallbackController)

  def index(conn, _params) do
    redirect(conn, to: Routes.play_path(conn, :show))
  end
end
