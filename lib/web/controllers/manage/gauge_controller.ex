defmodule Web.Manage.GaugeController do
  use Web, :controller

  alias GrapevineData.Games
  alias GrapevineData.Gauges

  def new(conn, %{"game_id" => game_id}) do
    %{current_user: user} = conn.assigns

    with {:ok, game} <- Games.get(user, game_id) do
      conn
      |> assign(:game, game)
      |> assign(:changeset, Gauges.new(game))
      |> render("new.html")
    end
  end

  def create(conn, %{"game_id" => game_id, "gauge" => params}) do
    %{current_user: user} = conn.assigns
    {:ok, game} = Games.get(user, game_id)

    with {:ok, _gauge} <- Gauges.create(game, params) do
      conn
      |> put_flash(:info, "Gauge created!")
      |> redirect(to: manage_game_client_path(conn, :show, game.id))
    else
      {:error, changeset} ->
        conn
        |> assign(:game, game)
        |> assign(:changeset, changeset)
        |> put_flash(:error, "There was an issue creating the gauge")
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    %{current_user: user} = conn.assigns

    with {:ok, gauge} <- Gauges.get(user, id) do
      conn
      |> assign(:gauge, gauge)
      |> assign(:game, gauge.game)
      |> assign(:changeset, Gauges.edit(gauge))
      |> render("edit.html")
    end
  end

  def update(conn, %{"id" => id, "gauge" => params}) do
    %{current_user: user} = conn.assigns
    {:ok, gauge} = Gauges.get(user, id)

    with {:ok, gauge} <- Gauges.update(gauge, params) do
      conn
      |> put_flash(:info, "Gauge updated")
      |> redirect(to: manage_game_client_path(conn, :show, gauge.game_id))
    else
      {:error, changeset} ->
        conn
        |> assign(:gauge, gauge)
        |> assign(:game, gauge.game)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end

  def delete(conn, %{"id" => id}) do
    %{current_user: user} = conn.assigns
    {:ok, gauge} = Gauges.get(user, id)

    with {:ok, gauge} <- Gauges.delete(gauge) do
      conn
      |> put_flash(:info, "Gauge deleted!")
      |> redirect(to: manage_game_client_path(conn, :show, gauge.game_id))
    end
  end
end
