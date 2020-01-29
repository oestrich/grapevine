defmodule Web.Admin.DashboardController do
  use Web, :controller

  alias GrapevineTelnet.Presence, as: TelnetPresence

  def index(conn, _params) do
    conn
    |> assign(:clients, TelnetPresence.online_clients())
    |> render("index.html")
  end
end
