defmodule Web.Admin.AlertController do
  use Web, :controller

  alias Grapevine.Alerts

  def index(conn, _params) do
    conn
    |> assign(:alerts, Alerts.recent_alerts())
    |> render("index.html")
  end
end
