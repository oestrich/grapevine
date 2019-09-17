defmodule Web.Hosted.GameView do
  use Web, :view

  alias Web.GameView
  alias Web.HostedRouter.Helpers, as: Routes
  alias Web.MarkdownView

  def render("connection-info.html", %{game: game}) do
    connections =
      Enum.filter(game.connections, fn connection ->
        connection.type == "telnet" || connection.type == "secure telnet"
      end)

    case Enum.count(connections) > 1 do
      true ->
        [telnet_connection(game), " | ", secure_telnet_connection(game)]

      false ->
        [telnet_connection(game), secure_telnet_connection(game)]
    end
  end

  def telnet_connection(game) do
    connection =
      Enum.find(game.connections, fn connection ->
        connection.type == "telnet"
      end)

    case connection != nil do
      true ->
        ["Telnet: ", connection.host, ":", to_string(connection.port)]

      false ->
        []
    end
  end

  def secure_telnet_connection(game) do
    connection =
      Enum.find(game.connections, fn connection ->
        connection.type == "secure telnet"
      end)

    case connection != nil do
      true ->
        ["Secure Telnet: ", connection.host, ":", to_string(connection.port)]

      false ->
        []
    end
  end
end
