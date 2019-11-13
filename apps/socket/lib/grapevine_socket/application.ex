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
      cluster_supervisor(),
      {GrapevineSocket.Presence, []},
      phoenix_pubsub(),
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: GrapevineSocket.Endpoint,
        options: [port: config[:port], dispatch: dispatch()]
      )
    ]

    children = Enum.reject(children, &is_nil/1)
    opts = [strategy: :one_for_one, name: GrapevineSocket.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dispatch() do
    [{:_, [{"/socket", GrapevineSocket.Web.SocketHandler, []}]}]
  end

  defp phoenix_pubsub() do
    pubsub = Application.get_env(:grapevine_socket, :pubsub)

    if pubsub[:start] do
      {Phoenix.PubSub.PG2, [name: Grapevine.PubSub]}
    end
  end

  defp cluster_supervisor() do
    topologies = Application.get_env(:grapevine_socket, :topologies)

    if topologies && Code.ensure_compiled?(Cluster.Supervisor) do
      {Cluster.Supervisor, [topologies, [name: GrapevineSocket.ClusterSupervisor]]}
    end
  end
end
