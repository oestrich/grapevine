defmodule Grapevine do
  @moduledoc """
  Grapevine keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @doc """
  Get the loaded version of Grapevine, to send when connecting.
  """
  def version() do
    {:grapevine, _, version} =
      Enum.find(:application.loaded_applications(), fn {app, _, _version} ->
        app == :grapevine
      end)

    to_string(version)
  end

  @doc """
  Version number for assets

  Bumping this will force a page reload of open browser tabs
  """
  def asset_versions(), do: 1

  @doc """
  Push a restart event to sockets
  """
  def restart(downtime \\ 15) do
    Web.Endpoint.broadcast("system", "restart", %{"downtime" => downtime})
  end
end
