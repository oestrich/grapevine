defmodule Web.Oauth.TokenView do
  use Web, :view

  def render("token.json", %{access_token: access_token}) do
    Map.take(access_token, [:access_token, :refresh_token, :expires_in])
  end

  def render("error.json", _assigns) do
    %{error: "invalid_request"}
  end
end
