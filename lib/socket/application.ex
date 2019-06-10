defmodule Socket.Application do
  @moduledoc """
  Supervisor for the Grapevine socket

  A supervisor hoping to become a full fledged application
  """

  use Supervisor

  @default_config [port: 4110]

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  def init(_) do
    config = Keyword.get(Application.get_env(:grapevine, :socket), :http, [])
    config = Keyword.merge(@default_config, config)

    children = [
      {Socket.Presence, []},
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Socket.Endpoint,
        options: [port: config[:port], dispatch: dispatch()]
      )
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp dispatch() do
    [{:_, [{"/socket", Socket.Web.SocketHandler, []}]}]
  end
end
