defmodule GrapevineData.Gauges do
  @moduledoc """
  Context for web client gauge's
  """

  import Ecto.Query

  alias GrapevineData.Gauges.Gauge
  alias GrapevineData.Repo

  def colors(), do: Gauge.colors()

  @doc """
  Changeset for a new gauge
  """
  def new(game) do
    game
    |> Ecto.build_assoc(:gauges)
    |> Gauge.changeset(%{})
  end

  @doc """
  Changeset for editing a gauge
  """
  def edit(gauge) do
    Gauge.changeset(gauge, %{})
  end

  @doc """
  Get gauges for a game
  """
  def for(game) do
    Gauge
    |> where([g], g.game_id == ^game.id)
    |> Repo.all()
  end

  @doc """
  Get a gauge scoped to a user's game
  """
  def get(user, id) do
    gauge =
      Gauge
      |> Repo.get(id)
      |> Repo.preload([:game])

    case is_nil(gauge) do
      true ->
        {:error, :not_found}

      false ->
        case gauge.game.user_id == user.id do
          true ->
            {:ok, gauge}

          false ->
            {:error, :not_found}
        end
    end
  end

  @doc """
  Create a new gauge
  """
  def create(game, params) do
    game
    |> Ecto.build_assoc(:gauges)
    |> Gauge.changeset(params)
    |> Repo.insert()
  end

  @doc """
  Update a gauge
  """
  def update(gauge, params) do
    gauge
    |> Gauge.changeset(params)
    |> Repo.update()
  end

  @doc """
  Delete a gauge from a game
  """
  def delete(gauge) do
    Repo.delete(gauge)
  end
end
