defmodule GossipWeb.PageController do
  use GossipWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
