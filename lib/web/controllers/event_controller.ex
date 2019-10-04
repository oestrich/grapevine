defmodule Web.EventController do
  use Web, :controller

  alias GrapevineData.Events

  action_fallback(Web.FallbackController)

  def index(conn, _params) do
    conn
    |> assign(:events, Events.next_month())
    |> assign(:title, "Upcoming Events - Grapevine")
    |> assign(:open_graph_title, "Upcoming Events")
    |> assign(:open_graph_description, "See upcoming events for games on Grapevine.")
    |> assign(:open_graph_url, event_url(conn, :index))
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    with {:ok, event} <- Events.get_uid(id),
         {:ok, _} <- Events.inc_view_count(event) do
      conn
      |> assign(:event, event)
      |> assign(:game, event.game)
      |> assign(:title, "Event - Grapevine")
      |> assign(:open_graph_url, Routes.event_url(conn, :show, event.uid))
      |> render("show.html")
    end
  end
end
