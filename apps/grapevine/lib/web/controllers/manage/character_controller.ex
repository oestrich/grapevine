defmodule Web.Manage.CharacterController do
  use Web, :controller

  alias GrapevineData.Characters
  alias GrapevineData.Games

  def index(conn, _params) do
    %{current_user: user} = conn.assigns

    conn
    |> assign(:characters, Characters.for(user))
    |> assign(:games, Games.for_user(user))
    |> render("index.html")
  end

  def approve(conn, %{"character_id" => id}) do
    %{current_user: user} = conn.assigns

    with {:ok, character} <- Characters.get(id),
         {:ok, character} <- Characters.check_user(character, user),
         {:ok, _character} <- Characters.approve_character(character) do
      conn
      |> put_flash(:info, "Character approved!")
      |> redirect(to: manage_character_path(conn, :index))
    else
      _ ->
        conn
        |> put_flash(:error, "An issue occurred. Please try again")
        |> redirect(to: manage_character_path(conn, :index))
    end
  end

  def deny(conn, %{"character_id" => id}) do
    %{current_user: user} = conn.assigns

    with {:ok, character} <- Characters.get(id),
         {:ok, character} <- Characters.check_user(character, user),
         {:ok, _character} <- Characters.deny_character(character) do
      conn
      |> put_flash(:info, "Character denied.")
      |> redirect(to: manage_character_path(conn, :index))
    else
      _ ->
        conn
        |> put_flash(:error, "An issue occurred. Please try again")
        |> redirect(to: manage_character_path(conn, :index))
    end
  end
end
