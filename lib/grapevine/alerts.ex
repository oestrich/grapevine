defmodule Grapevine.Alerts do
  @moduledoc """
  Context for alerts
  """

  alias Grapevine.Alerts.Alert
  alias Grapevine.Emails
  alias Grapevine.Mailer
  alias Grapevine.Repo

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
