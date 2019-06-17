defmodule Grapevine.Alerts do
  @moduledoc """
  Context for alerts
  """

  import Ecto.Query

  alias Grapevine.Alerts.Alert
  alias Grapevine.Emails
  alias Grapevine.Mailer
  alias Data.Repo

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
  def create(title, body) do
    changeset = Alert.changeset(%Alert{}, title, body)

    case Repo.insert(changeset) do
      {:ok, alert} ->
        alert
        |> Emails.new_alert()
        |> Mailer.deliver_later()

        {:ok, alert}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
