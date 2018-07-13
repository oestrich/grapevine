defmodule Web.SocketHandler do
  @moduledoc """
  Cowboy WebSocket handler
  """

  @behaviour :cowboy_websocket_handler

  alias Web.Socket.Implementation
  alias Web.Socket.State
  alias Metrics.Server, as: Metrics

  require Logger

  @heartbeat_interval 15_000

  def init(_, _req, _opts) do
    {:upgrade, :protocol, :cowboy_websocket}
  end

  def websocket_init(_type, req, _opts) do
    :timer.send_interval(@heartbeat_interval, :heartbeat)

    Logger.info("Socket starting")
    Metrics.socket_online()

    {:ok, req, %State{status: "inactive"}}
  end

  def websocket_handle({:text, message}, req, state) do
    with {:ok, message} <- Poison.decode(message),
         {:ok, response, state} <- Implementation.receive(state, message) do
      respond(state, req, response)
    else
      {:ok, state} ->
        {:ok, req, state}

      {:disconnect, response, state} ->
        send(self(), {:disconnect})

        {:reply, {:text, Poison.encode!(response)}, req, state}

      _ ->
        {:reply, {:text, Poison.encode!(%{status: "unknown"})}, req, state}
    end
  end

  def websocket_handle({:ping, message}, req, state) do
    {:reply, {:pong, message}, req, state}
  end

  def websocket_info({:broadcast, event}, req, state) do
    {:reply, {:text, Poison.encode!(event)}, req, state}
  end

  # Ignore broadcasts from the same client id
  def websocket_info(message = %Phoenix.Socket.Broadcast{}, req, state) do
    client_id = state.game.client_id

    case Map.get(message.payload, "game_id") do
      ^client_id ->
        {:ok, req, state}

      _ ->
        message = %{
          event: message.event,
          ref: UUID.uuid4(),
          payload: Map.delete(message.payload, "game_id"),
        }

        {:reply, {:text, Poison.encode!(message)}, req, state}
    end
  end

  def websocket_info(:heartbeat, req, state) do
    case Implementation.heartbeat(state) do
      {:ok, response, state} ->
        {:reply, {:text, Poison.encode!(response)}, req, state}

      {:disconnect, state} ->
        Logger.warn("Disconnecting the socket")
        {:reply, {:close, 4001, "goodbye"}, req, state}
    end
  end

  def websocket_info({:disconnect}, req, state) do
    {:reply, {:close, 4000, "goodbye"}, req, state}
  end

  def websocket_info(_message, req, state) do
    {:reply, {:text, "error"}, req, state}
  end

  def websocket_terminate(_reason, _req, _state) do
    :ok
  end

  defp respond(state, req, :skip) do
    {:ok, req, state}
  end

  defp respond(state, req, response) do
    {:reply, {:text, Poison.encode!(response)}, req, state}
  end
end
