defmodule Web.Admin.ClientSessionController do
  use Web, :controller

  alias GrapevineData.Statistics

  plug(Web.Plugs.FetchPage)

  def index(conn, _params) do
    %{page: page, per: per} = conn.assigns
    %{page: sessions, pagination: pagination} = Statistics.recent_sessions(page: page, per: per)

    conn
    |> assign(:sessions, sessions)
    |> assign(:pagination, pagination)
    |> render("index.html")
  end
end
