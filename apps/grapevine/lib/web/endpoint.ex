defmodule Web.Endpoint do
  use Phoenix.Endpoint, otp_app: :grapevine
  use Plug.ErrorHandler
  use Sentry.Plug

  socket("/websocket", Web.UserSocket,
    websocket: [check_origin: false, connect_info: [:peer_data, :x_headers]]
  )

  socket("/live", Phoenix.LiveView.Socket)

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug(Plug.Static,
    at: "/",
    from: :grapevine,
    gzip: true,
    only: ~w(css fonts images js favicon.ico robots.txt)
  )

  if Mix.env() == :dev do
    plug(Plug.Static, at: "/uploads", from: "uploads/files")
  end

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.RequestId)
  plug(Logster.Plugs.Logger)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  plug(Metrics.PlugExporter)

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug(Plug.Session,
    store: :cookie,
    key: "_grapevine_key",
    signing_salt: "8eezNeWe"
  )

  plug(Web.SplitRouter)

  @doc """
  Callback invoked for dynamically configuring the endpoint.

  It receives the endpoint configuration and checks if
  configuration should be loaded from the system environment.
  """
  def init(_key, config) do
    {:ok, config}
  end
end
