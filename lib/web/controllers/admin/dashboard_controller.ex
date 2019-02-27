defmodule Web.Admin.DashboardController do
  use Web, :controller

  alias Telnet.Metrics.Server, as: TelnetServer

  def index(conn, _params) do
    conn
    |> assign(:clients, TelnetServer.online_clients())
    |> render("index.html")
  end
end
