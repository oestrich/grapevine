defmodule Grapevine.Statistics.Server do
  @moduledoc """
  GenServer to register globally for updating session state
  """

  use GenServer

  alias GrapevineData.Statistics

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: {:global, Grapevine.Statistics})
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_cast({:start_session, game, sid}, state) do
    Statistics.record_web_client_started(game, sid)
    {:noreply, state}
  end

  def handle_cast({:close_session, sid}, state) do
    Statistics.record_web_client_closed(sid)
    {:noreply, state}
  end
end
