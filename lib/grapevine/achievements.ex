defmodule Grapevine.Achievements do
  @moduledoc """
  Contect for managing a game's achievements
  """

  import Ecto.Query

  alias Grapevine.Achievements.Achievement
  alias Grapevine.Repo
  alias Grapevine.Versions

  @max_points 500

  @doc """
  Re-sync all achievements

  NOTE: This must be run in the same node as the socket connections
  """
  def resync() do
    Achievement
    |> select([a], a.id)
    |> Repo.all()
    |> Enum.map(&broadcast_achievement_update/1)
  end

  @doc """
  New changeset for an achievement
  """
  def new(game) do
    game
    |> Ecto.build_assoc(:achievements)
    |> Achievement.changeset(%{})
  end

  @doc """
  Edit changeset for an achievement
  """
  def edit(achievement) do
    achievement
    |> Achievement.changeset(%{})
  end

  @doc """
  Get all achievements for a game
  """
  def for(game) do
    Achievement
    |> where([a], a.game_id == ^game.id)
    |> order_by([a], asc: a.title)
    |> Repo.all()
  end

  @doc """
  Get an achievement for a user

  Scoped to the user
  """
  def get(user, id) do
    case Repo.get(Achievement, id) do
      nil ->
        {:error, :not_found}

      achievement ->
        achievement = Repo.preload(achievement, [:game])

        case achievement.game.user_id == user.id do
          true ->
            {:ok, achievement}

          false ->
            {:error, :not_found}
        end
    end
  end

  @doc """
  Get by the key
  """
  def get_by_key(game, key) do
    case Repo.get_by(Achievement, game_id: game.id, key: key) do
      nil ->
        {:error, :not_found}

      achievement ->
        {:ok, achievement}
    end
  end

  @doc """
  Get total points for a game
  """
  def total_points(game) do
    Achievement
    |> where([a], a.game_id == ^game.id)
    |> select([a], fragment("coalesce(?, 0)", sum(a.points)))
    |> Repo.one()
  end

  @doc """
  Get an achievement and preload it
  """
  def get(id) do
    case Repo.get(Achievement, id) do
      nil ->
        {:error, :not_found}

      achievement ->
        {:ok, Repo.preload(achievement, [:game])}
    end
  end

  @doc """
  Create a new achievement for a game
  """
  def create(game, params) do
    changeset =
      game
      |> Ecto.build_assoc(:achievements)
      |> Achievement.changeset(params)

    case total_points(game) < @max_points do
      true ->
        _create(game, changeset)

      false ->
        changeset
        |> Ecto.Changeset.add_error(:points, "no points left")
        |> Repo.insert()
    end
  end

  defp _create(game, changeset) do
    case Repo.insert(changeset) do
      {:ok, achievement} ->
        :telemetry.execute([:grapevine, :achievements, :create, :success], 1, %{game_id: game.id})
        broadcast_achievement_create(achievement.id)
        {:ok, achievement}

      {:error, changeset} ->
        :telemetry.execute([:grapevine, :achievements, :create, :failure], 1, %{game_id: game.id})
        {:error, changeset}
    end
  end

  @doc """
  Update a game for an achievement
  """
  def update(achievement, params) do
    changeset = achievement |> Achievement.changeset(params)

    case Repo.update(changeset) do
      {:ok, achievement} ->
        :telemetry.execute([:grapevine, :achievements, :update, :success], 1, %{
          game_id: achievement.game_id
        })

        broadcast_achievement_update(achievement.id)
        {:ok, achievement}

      {:error, changeset} ->
        :telemetry.execute([:grapevine, :achievements, :update, :failure], 1, %{
          game_id: achievement.game_id
        })

        {:error, changeset}
    end
  end

  @doc """
  Delete an achievement
  """
  def delete(achievement) do
    case Repo.delete(achievement) do
      {:ok, achievement} ->
        :telemetry.execute([:grapevine, :achievements, :delete, :success], 1, %{
          game_id: achievement.game_id
        })

        broadcast_achievement_delete(achievement)
        {:ok, achievement}

      {:error, changeset} ->
        :telemetry.execute([:grapevine, :achievements, :delete, :failure], 1, %{
          game_id: achievement.game_id
        })

        {:error, changeset}
    end
  end

  defp broadcast_achievement_create(achievement_id) do
    with {:ok, achievement} <- get(achievement_id),
         {:ok, version} <- Versions.log("create", achievement) do
      Web.Endpoint.broadcast("system:backbone", "achievements/new", version)
    else
      _ ->
        :ok
    end
  end

  defp broadcast_achievement_update(achievement_id) do
    with {:ok, achievement} <- get(achievement_id),
         {:ok, version} <- Versions.log("update", achievement) do
      Web.Endpoint.broadcast("system:backbone", "achievements/edit", version)
    else
      _ ->
        :ok
    end
  end

  defp broadcast_achievement_delete(achievement) do
    with {:ok, version} <- Versions.log("delete", achievement) do
      Web.Endpoint.broadcast("system:backbone", "achievements/delete", version)
    else
      _ ->
        :ok
    end
  end
end
