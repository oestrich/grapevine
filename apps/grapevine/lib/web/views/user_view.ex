defmodule Web.UserView do
  use Web, :view

  def render("show.json", %{user: user, scopes: scopes}) do
    case "email" in scopes do
      true ->
        Map.take(user, [:uid, :username, :email])

      false ->
        Map.take(user, [:uid, :username])
    end
  end
end
