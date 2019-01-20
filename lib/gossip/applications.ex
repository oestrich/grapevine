defmodule Grapevine.Applications do
  @moduledoc """
  Context for system level applications
  """

  alias Grapevine.Applications.Application
  alias Grapevine.Repo

  @type id :: integer()
  @type attributes :: map()

  @doc """
  Fetch an application
  """
  @spec get(id()) :: {:ok, Application.t()} | {:error, :not_found}
  def get(id) do
    case Repo.get(Application, id) do
      nil ->
        {:error, :not_found}

      application ->
        {:ok, application}
    end
  end

  @doc """
  """
  @spec create(attributes()) :: {:ok, Application.t()}
  def create(attributes) do
    %Application{}
    |> Application.changeset(attributes)
    |> Repo.insert()
  end

  @doc """
  Validate a socket for a network application
  """
  @spec validate_socket(Games.uuid(), Games.uuid()) :: {:ok, Application.t()} | {:error, :invalid}
  def validate_socket(client_id, client_secret) do
    with {:ok, client_id} <- Ecto.UUID.cast(client_id),
         {:ok, client_secret} <- Ecto.UUID.cast(client_secret),
         {:ok, application} <- get_application(client_id),
         {:ok, application} <- validate_secret(application, client_secret) do
      {:ok, application}
    else
      _ ->
        {:error, :invalid}
    end
  end

  defp get_application(client_id) do
    case Repo.get_by(Application, client_id: client_id) do
      nil ->
        {:error, :invalid}

      application ->
        {:ok, application}
    end
  end

  defp validate_secret(application, client_secret) do
    case application.client_secret == client_secret do
      true ->
        {:ok, application}

      false ->
        {:error, :invalid}
    end
  end
end
