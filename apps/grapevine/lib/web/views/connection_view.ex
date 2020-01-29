defmodule Web.ConnectionView do
  use Web, :view

  def render("show.json", %{connection: connection}) do
    case connection.type do
      "telnet" ->
        Map.take(connection, [:type, :host, :port])

      "secure telnet" ->
        Map.take(connection, [:type, :host, :port])

      "web" ->
        Map.take(connection, [:type, :url])
    end
  end
end
