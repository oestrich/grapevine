defmodule GrapevineTelnet.Statistics do
  @moduledoc """
  Record statistics about open web clients
  """

  def session_started(game, sid) do
    GenServer.cast(statistics_pid(), {:start_session, game, sid})
  end

  def session_closed(sid) do
    GenServer.cast(statistics_pid(), {:close_session, sid})
  end

  defp statistics_pid() do
    case :pg2.get_closest_pid(Grapevine.Statistics) do
      {:error, reason} ->
        raise "Could not find closest pid for statistics - #{inspect(reason)}"

      pid ->
        pid
    end
  end
end
