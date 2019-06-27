defmodule GrapevineData.UserAgents do
  @moduledoc """
  User agent context
  """

  alias GrapevineData.Repo
  alias GrapevineData.UserAgents.UserAgent

  @type user_agent :: String.t()

  @doc """
  Register a connecting games user agent
  """
  @spec register_user_agent(user_agent()) :: {:ok, UserAgent.t()}
  def register_user_agent(version) do
    case get_user_agent(version) do
      {:ok, user_agent} ->
        {:ok, user_agent}

      {:error, :not_found} ->
        create_user_agent(version)
    end
  end

  defp create_user_agent(version) do
    %UserAgent{}
    |> UserAgent.changeset(%{version: version})
    |> Repo.insert()
  end

  @doc """
  Get a user agent by its version string
  """
  @spec get_user_agent(user_agent()) :: {:ok, UserAgent.t()} | {:error, :not_found}
  def get_user_agent(version) do
    case Repo.get_by(UserAgent, version: version) do
      nil ->
        {:error, :not_found}

      user_agent ->
        {:ok, user_agent}
    end
  end
end
