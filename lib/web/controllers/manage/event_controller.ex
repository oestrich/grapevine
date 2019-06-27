defmodule Web.Manage.EventController do
  use Web, :controller

  alias GrapevineData.Games
  alias GrapevineData.Events

  plug(Web.Plugs.VerifyUser)

  def index(conn, %{"game_id" => game_id}) do
    %{current_user: user} = conn.assigns

    with {:ok, game} <- Games.get(user, game_id) do
      conn
      |> assign(:game, game)
      |> assign(:events, Events.for(game))
      |> render("index.html")
    end
  end

  def new(conn, %{"game_id" => game_id}) do
    %{current_user: user} = conn.assigns

    with {:ok, game} <- Games.get(user, game_id) do
      conn
      |> assign(:game, game)
      |> assign(:changeset, Events.new(game))
      |> render("new.html")
    end
  end

  def create(conn, %{"game_id" => game_id, "event" => params}) do
    %{current_user: user} = conn.assigns

    with {:ok, game} <- Games.get(user, game_id),
         {:ok, _event} <- Events.create(game, params) do
      redirect(conn, to: manage_game_event_path(conn, :index, game.id))
    else
      {:error, changeset} ->
        {:ok, game} = Games.get(user, game_id)

        conn
        |> assign(:game, game)
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    %{current_user: user} = conn.assigns

    with {:ok, event} = Events.get(user, id),
         {:ok, game} = Games.get(user, event.game_id) do
      conn
      |> assign(:event, event)
      |> assign(:game, game)
      |> assign(:changeset, Events.edit(event))
      |> render("edit.html")
    end
  end

  def update(conn, %{"id" => id, "event" => params}) do
    %{current_user: user} = conn.assigns

    with {:ok, event} <- Events.get(user, id),
         {:ok, event} <- Events.update(event, params) do
      redirect(conn, to: manage_game_event_path(conn, :index, event.game_id))
    else
      {:error, changeset} ->
        {:ok, event} = Events.get(user, id)
        {:ok, game} = Games.get(user, event.game_id)

        conn
        |> assign(:event, event)
        |> assign(:game, game)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end

  def delete(conn, %{"id" => id}) do
    %{current_user: user} = conn.assigns

    with {:ok, event} <- Events.get(user, id),
         {:ok, event} <- Events.delete(event) do
      redirect(conn, to: manage_game_event_path(conn, :index, event.game_id))
    end
  end
end
