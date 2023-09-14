defmodule GrapevineData.Alerts do
  @moduledoc """
  Context for alerts
  """

  import Ecto.Query

  alias GrapevineData.Alerts.Alert
  alias GrapevineData.Notifications
  alias GrapevineData.Repo

  @doc """
  The most recent 20 alerts
  """
  def recent_alerts() do
    Alert
    |> order_by([a], desc: a.id)
    |> limit(20)
    |> Repo.all()
  end

  @doc """
  Create a new alert
  """
  def create(title, body, notification_opts \\ []) do
    %Alert{}
    |> Alert.changeset(title, body)
    |> Repo.insert()
  end
end
