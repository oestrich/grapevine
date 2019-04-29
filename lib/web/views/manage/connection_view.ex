defmodule Web.Manage.ConnectionView do
  use Web, :view

  alias Web.FormView

  def render("show.json", %{connection: connection}) do
    json = render("connection.json", %{connection: connection})
    Map.put(json, :id, connection.key)
  end

  def render("connection.json", %{connection: connection}) do
    case connection.type do
      "web" ->
        Map.take(connection, [:type, :url])

      "telnet" ->
        Map.take(connection, [:type, :host, :port])

      "secure telnet" ->
        Map.take(connection, [:type, :host, :port])
    end
  end

  def connection_info(connection) do
    case connection.type do
      "web" ->
        connection.url

      "telnet" ->
        "#{connection.host}:#{connection.port}"

      "secure telnet" ->
        "#{connection.host}:#{connection.port}"
    end
  end
end
