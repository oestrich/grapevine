defmodule Web.Admin.EventController do
  use Web, :controller

  alias GrapevineData.Events

  plug(Web.Plugs.FetchPage)

  def index(conn, _params) do
    %{page: page, per: per} = conn.assigns
    %{page: events, pagination: pagination} = Events.all(page: page, per: per)

    conn
    |> assign(:events, events)
    |> assign(:pagination, pagination)
    |> render("index.html")
  end

  def show(conn, %{"id" => uid}) do
    with {:ok, event} <- Events.get_uid(uid) do
      conn
      |> assign(:event, event)
      |> assign(:game, event.game)
      |> render("show.html")
    end
  end

  def new(conn, _params) do
    conn
    |> assign(:changeset, Events.new())
    |> render("new.html")
  end

  def create(conn, %{"event" => params}) do
    with {:ok, event} <- Events.create(params) do
      redirect(conn, to: Routes.admin_event_path(conn, :show, event.uid))
    else
      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => uid}) do
    with {:ok, event} <- Events.get_uid(uid) do
      conn
      |> assign(:event, event)
      |> assign(:changeset, Events.edit(event))
      |> render("edit.html")
    end
  end

  def update(conn, %{"id" => uid, "event" => params}) do
    with {:ok, event} <- Events.get_uid(uid),
         {:ok, event} <- Events.update(event, params) do
      redirect(conn, to: Routes.admin_event_path(conn, :show, event.uid))
    else
      {:error, changeset} ->
        {:ok, event} = Events.get_uid(uid)

        conn
        |> assign(:event, event)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end

  def delete(conn, %{"id" => uid}) do
    with {:ok, event} <- Events.get_uid(uid),
         {:ok, _event} <- Events.delete(event) do
      redirect(conn, to: Routes.admin_event_path(conn, :index))
    end
  end
end
