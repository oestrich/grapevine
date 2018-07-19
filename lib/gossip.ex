defmodule Gossip do
  @moduledoc """
  Gossip keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @doc """
  Get the loaded version of Gossip, to send when connecting.
  """
  def version() do
    elem(Enum.find(:application.loaded_applications(), &(elem(&1, 0) == :gossip)), 2)
  end

  @doc """
  Push a restart event to sockets
  """
  def restart(downtime) do
    Web.Endpoint.broadcast("restart", "restart", %{"downtime" => downtime})
  end
end
