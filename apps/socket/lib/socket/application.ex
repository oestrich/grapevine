defmodule GrapevineSocket.Application do
  @moduledoc """
  Supervisor for the Grapevine socket

  A supervisor hoping to become a full fledged application
  """

  use Application

  @default_config [port: 4110]

  def start(_type, _args) do
    config = Application.get_env(:grapevine_socket, :http, [])
    config = Keyword.merge(@default_config, config)

    children = [
      {Socket.Presence, []},
      phoenix_pubsub(),
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Socket.Endpoint,
        options: [port: config[:port], dispatch: dispatch()]
      )
    ]

    children = Enum.reject(children, &is_nil/1)
    opts = [strategy: :one_for_one, name: GrapevineSocket.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dispatch() do
    [{:_, [{"/socket", Socket.Web.SocketHandler, []}]}]
  end

  defp phoenix_pubsub() do
    pubsub = Application.get_env(:grapevine_socket, :pubsub)

    if pubsub[:start] do
      {Phoenix.PubSub.PG2, [name: Grapevine.PubSub]}
    end
  end
end
