defmodule Web.SessionTokenView do
  use Web, :view

  def render("token.json", %{session_token: token}) do
    token
    |> show()
    |> Representer.transform("json")
  end

  def show(token) do
    %Representer.Item{
      data: %{token: token}
    }
  end
end
