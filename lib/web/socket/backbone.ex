defmodule Web.Socket.Backbone do
  @moduledoc """
  Backbone processing for application sockets

  Backbone events:
  - "channels/new", payload is the new channel
  """

  alias Gossip.Applications.Application
  alias Gossip.Channels

  @doc """
  Process a system backbone message

  Gates the state for a connected application before processing
  """
  def event(state, message) do
    with {:ok, :application} <- check_for_application(state) do
      process_event(state, message)
    else
      _ ->
        {:ok, state}
    end
  end

  @doc """
  Process a system backbone message
  """
  def process_event(state, message = %{event: "channels/new"}) do
    Web.Endpoint.subscribe("channels:#{message.payload.name}")

    {:ok, state}
  end

  def process_event(state, _message), do: {:ok, state}

  @doc """
  If the connected game is a system application, perform extra finalizations

  - Subscribe to all channels
  - Listen to new channels
  """
  def maybe_finalize_authenticate(state) do
    with {:ok, :application} <- check_for_application(state) do
      subscribe_to_backbone()
      subscribe_to_all()
    end
  end

  defp check_for_application(state) do
    case state.game do
      %Application{} ->
        {:ok, :application}

      _ ->
        {:error, :not_application}
    end
  end

  defp subscribe_to_backbone() do
    Web.Endpoint.subscribe("system:backbone")
  end

  defp subscribe_to_all() do
    channels = Channels.all(include_hidden: true)
    Enum.each(channels, fn channel ->
      Web.Endpoint.subscribe("channels:#{channel.name}")
    end)
  end
end
