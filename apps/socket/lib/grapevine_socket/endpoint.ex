defmodule GrapevineSocket.Endpoint do
  use Plug.Router

  plug(GrapevineSocket.Metrics.PlugExporter)

  plug(:match)
  plug(:dispatch)

  match _ do
    send_resp(conn, 404, "")
  end
end
