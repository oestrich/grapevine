defmodule Web.SocketHandler do
  @moduledoc """
  Cowboy WebSocket handler
  """

  @behaviour :cowboy_websocket

  alias Metrics.Server, as: Metrics
  alias Socket.Core.Heartbeat
  alias Web.Socket.Router
  alias Web.Socket.State

  require Logger

  @heartbeat_interval 15_000

  def init(req, opts) do
    {:cowboy_websocket, req, opts}
  end

  def websocket_init(_state) do
    :timer.send_interval(@heartbeat_interval, :heartbeat)

    Logger.info("Socket starting")
    Metrics.socket_online()

    # General purpose channels
    Web.Endpoint.subscribe("system")

    {:ok, %State{status: "inactive"}}
  end

  def websocket_handle({:text, message}, state) do
    Logger.debug(message, type: :socket)

    with {:ok, message} <- Jason.decode(message),
         {:ok, response, state} <- Router.receive(state, message) do
      respond(state, response)
    else
      {:ok, state} ->
        {:ok, state}

      {:disconnect, response, state} ->
        send(self(), {:disconnect})

        {:reply, {:text, Jason.encode!(response)}, state}

      _ ->
        {:reply, {:text, Jason.encode!(%{status: "failure", error: "unknown"})}, state}
    end
  end

  def websocket_handle({:ping, message}, state) do
    {:reply, {:pong, message}, state}
  end

  def websocket_info({:broadcast, event}, state) do
    {:reply, {:text, Jason.encode!(event)}, state}
  end

  # Ignore broadcasts from the same client id
  def websocket_info(message = %Phoenix.Socket.Broadcast{event: "restart"}, state) do
    message = %{
      event: "restart",
      ref: UUID.uuid4(),
      payload: %{
        downtime: message.payload["downtime"] + Enum.random(-5..5)
      }
    }

    {:reply, {:text, Jason.encode!(message)}, state}
  end

  def websocket_info(message = %Phoenix.Socket.Broadcast{topic: "system:backbone"}, state) do
    case Router.backbone_event(state, message) do
      {:ok, state} ->
        {:ok, state}

      {:ok, response, state} ->
        {:reply, {:text, Jason.encode!(response)}, state}
    end
  end

  def websocket_info(message = %Phoenix.Socket.Broadcast{}, state) do
    client_id = state.game.client_id

    case Map.get(message.payload, "game_id") do
      ^client_id ->
        {:ok, state}

      _ ->
        message = %{
          event: message.event,
          ref: UUID.uuid4(),
          payload: Map.delete(message.payload, "game_id")
        }

        {:reply, {:text, Jason.encode!(message)}, state}
    end
  end

  def websocket_info(:heartbeat, state) do
    case Heartbeat.handle(state) do
      {:ok, state} ->
        {:ok, state}

      {:ok, response, state} ->
        {:reply, {:text, Jason.encode!(response)}, state}

      {:disconnect, state} ->
        Logger.warn("Disconnecting the socket")
        {:reply, {:close, 4001, "goodbye"}, state}
    end
  end

  def websocket_info({:disconnect}, state) do
    {:reply, {:close, 4000, "goodbye"}, state}
  end

  def websocket_info({:disable_debug}, state) do
    {:ok, %{state | debug: false}}
  end

  def websocket_info(_message, state) do
    {:ok, state}
  end

  def websocket_terminate(_reason, _req, _state) do
    :ok
  end

  defp respond(state, :skip) do
    {:ok, state}
  end

  defp respond(state, response) do
    {:reply, {:text, Jason.encode!(response)}, state}
  end
end
