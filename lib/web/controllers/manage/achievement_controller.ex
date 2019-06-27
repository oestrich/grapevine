defmodule Web.Manage.AchievementController do
  use Web, :controller

  alias GrapevineData.Games
  alias GrapevineData.Achievements

  plug(Web.Plugs.VerifyUser)

  def index(conn, %{"game_id" => game_id}) do
    %{current_user: user} = conn.assigns

    with {:ok, game} <- Games.get(user, game_id) do
      conn
      |> assign(:game, game)
      |> assign(:achievements, Achievements.for(game))
      |> render("index.html")
    end
  end

  def new(conn, %{"game_id" => game_id}) do
    %{current_user: user} = conn.assigns

    with {:ok, game} <- Games.get(user, game_id) do
      conn
      |> assign(:game, game)
      |> assign(:changeset, Achievements.new(game))
      |> render("new.html")
    end
  end

  def create(conn, %{"game_id" => game_id, "achievement" => params}) do
    %{current_user: user} = conn.assigns

    with {:ok, game} <- Games.get(user, game_id),
         {:ok, _achievement} <- Achievements.create(game, params) do
      redirect(conn, to: manage_game_achievement_path(conn, :index, game.id))
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

    with {:ok, achievement} = Achievements.get(user, id),
         {:ok, game} = Games.get(user, achievement.game_id) do
      conn
      |> assign(:achievement, achievement)
      |> assign(:game, game)
      |> assign(:changeset, Achievements.edit(achievement))
      |> render("edit.html")
    end
  end

  def update(conn, %{"id" => id, "achievement" => params}) do
    %{current_user: user} = conn.assigns

    with {:ok, achievement} <- Achievements.get(user, id),
         {:ok, achievement} <- Achievements.update(achievement, params) do
      redirect(conn, to: manage_game_achievement_path(conn, :index, achievement.game_id))
    else
      {:error, changeset} ->
        {:ok, achievement} = Achievements.get(user, id)
        {:ok, game} = Games.get(user, achievement.game_id)

        conn
        |> assign(:achievement, achievement)
        |> assign(:game, game)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end

  def delete(conn, %{"id" => id}) do
    %{current_user: user} = conn.assigns

    with {:ok, achievement} <- Achievements.get(user, id),
         {:ok, achievement} <- Achievements.delete(achievement) do
      redirect(conn, to: manage_game_achievement_path(conn, :index, achievement.game_id))
    end
  end
end
