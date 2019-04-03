defmodule Web.EventController do
  use Web, :controller

  alias Grapevine.Events

  def index(conn, _params) do
    conn
    |> assign(:events, Events.next_month())
    |> assign(:title, "Upcoming Events - Grapevine")
    |> assign(:open_graph_title, "Upcoming Events")
    |> assign(:open_graph_description, "See upcoming events for games on Grapevine.")
    |> assign(:open_graph_url, event_url(conn, :index))
    |> render("index.html")
  end
end
