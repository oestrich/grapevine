defmodule GrapevineTelnet.Statistics do
  @moduledoc """
  Record statistics about open web clients
  """

  def session_started(game, sid) do
    GenServer.cast({:global, Grapevine.Statistics}, {:start_session, game, sid})
  end

  def session_closed(sid) do
    GenServer.cast({:global, Grapevine.Statistics}, {:close_session, sid})
  end
end
