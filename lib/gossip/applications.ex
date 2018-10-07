defmodule Gossip.Applications do
  @moduledoc """
  Context for system level applications
  """

  alias Gossip.Applications.Application
  alias Gossip.Repo

  @type attributes :: map()

  @doc """
  """
  @spec create_application(attributes()) :: {:ok, Application.t()}
  def create_application(attributes) do
    %Application{}
    |> Application.changeset(attributes)
    |> Repo.insert()
  end
end
