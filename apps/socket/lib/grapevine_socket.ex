defmodule GrapevineSocket do
  @moduledoc """
  Documentation for GrapevineSocket.
  """

  def version() do
    {:grapevine_socket, _, version} =
      Enum.find(:application.loaded_applications(), fn {app, _, _version} ->
        app == :grapevine_socket
      end)

    to_string(version)
  end
end
