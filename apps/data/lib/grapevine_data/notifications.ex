defmodule GrapevineData.Notifications do
  @moduledoc """
  PubSub for GrapevineData
  """

  @doc """
  Notify of a new alert
  """
  def new_alert(alert, notification_opts) do
    closest_pid(fn pid ->
      GenServer.cast(pid, {:new_alert, alert, notification_opts})
    end)
  end

  @doc """
  Notify of a new game that registered
  """
  def new_game(game) do
    closest_pid(fn pid ->
      GenServer.cast(pid, {:new_game, game})
    end)
  end

  defp closest_pid(fun) do
    case :pg2.get_closest_pid(Grapevine.Notifications) do
      pid when is_pid(pid) ->
        fun.(pid)

      {:error, _reason} ->
        :ok
    end
  end
end
