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
    to_string(
      elem(Enum.find(:application.loaded_applications(), &(elem(&1, 0) == :grapevine)), 2)
    )
  end

  @doc """
  Push a restart event to sockets
  """
  def restart(downtime \\ 15) do
    Web.Endpoint.broadcast("system", "restart", %{"downtime" => downtime})
  end
end
