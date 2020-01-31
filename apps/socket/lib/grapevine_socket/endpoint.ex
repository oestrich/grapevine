defmodule GrapevineSocket.Endpoint do
  use Plug.Router

  plug(GrapevineSocket.Metrics.PlugExporter)

  plug(:match)
  plug(:dispatch)

  match "/_health" do
    send_resp(conn, 200, "")
  end

  match _ do
    send_resp(conn, 404, "")
  end
end
