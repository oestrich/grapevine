defmodule Socket.Handler.Achievements do
  @moduledoc """
  Achievement management
  """

  use Socket.Web.Module

  alias GrapevineData.Achievements

  @doc """
  Sync the list of achievements
  """
  def sync(state, %{"ref" => ref}) when ref != nil do
    achievements = Achievements.for(state.game)
    total = Enum.count(achievements)

    case total == 0 do
      true ->
        broadcast_achievements(ref, [], 0)

      false ->
        achievements
        |> Enum.chunk_every(10)
        |> Enum.each(&broadcast_achievements(ref, &1, total))
    end

    {:ok, :skip, state}
  end

  def sync(_state, _frame), do: :error

  @doc """
  Create a new achievement
  """
  def create(state, %{"ref" => ref, "payload" => params}) when ref != nil do
    :telemetry.execute([:grapevine, :events, :achievements, :create], %{count: 1}, %{})

    case Achievements.create(state.game, params) do
      {:ok, achievement} ->
        response =
          token()
          |> assign(:ref, ref)
          |> assign(:event, "achievements/create")
          |> assign(:achievement, achievement)
          |> event("update")

        {:ok, response.payload, state}

      {:error, changeset} ->
        response =
          token()
          |> assign(:ref, ref)
          |> assign(:event, "achievements/create")
          |> assign(:changeset, changeset)
          |> event("errors")

        {:ok, response.payload, state}
    end
  end

  def create(_state, _frame), do: :error

  @doc """
  Update an achievement
  """
  def update(state, %{"ref" => ref, "payload" => params}) when ref != nil do
    :telemetry.execute([:grapevine, :events, :achievements, :update], %{count: 1}, %{})

    with {:ok, key} <- Map.fetch(params, "key"),
         {:ok, achievement} <- Achievements.get_by_key(state.game, key),
         {:ok, achievement} <- Achievements.update(achievement, params) do
      response =
        token()
        |> assign(:ref, ref)
        |> assign(:event, "achievements/update")
        |> assign(:achievement, achievement)
        |> event("update")

      {:ok, response.payload, state}
    else
      :error ->
        not_found(state, ref, "achievements/update")

      {:error, :not_found} ->
        not_found(state, ref, "achievements/update")

      {:error, changeset} ->
        response =
          token()
          |> assign(:ref, ref)
          |> assign(:event, "achievements/update")
          |> assign(:changeset, changeset)
          |> event("errors")

        {:ok, response.payload, state}
    end
  end

  def update(_state, _frame), do: :error

  @doc """
  Delete an achievement
  """
  def delete(state, %{"ref" => ref, "payload" => params}) when ref != nil do
    :telemetry.execute([:grapevine, :events, :achievements, :delete], %{count: 1}, %{})

    with {:ok, key} <- Map.fetch(params, "key"),
         {:ok, achievement} <- Achievements.get_by_key(state.game, key),
         {:ok, achievement} <- Achievements.delete(achievement) do
      response =
        token()
        |> assign(:ref, ref)
        |> assign(:event, "achievements/delete")
        |> assign(:achievement, achievement)
        |> event("delete")

      {:ok, response.payload, state}
    else
      :error ->
        not_found(state, ref, "achievements/delete")

      {:error, :not_found} ->
        not_found(state, ref, "achievements/delete")
    end
  end

  def delete(_state, _frame), do: :error

  def not_found(state, ref, event) do
    response =
      token()
      |> assign(:ref, ref)
      |> assign(:event, event)
      |> event("not-found")

    {:ok, response.payload, state}
  end

  defp broadcast_achievements(ref, achievements, total) do
    token()
    |> assign(:ref, ref)
    |> assign(:total, total)
    |> assign(:achievements, achievements)
    |> event("sync")
    |> relay()
  end

  defmodule View do
    @moduledoc """
    "View" module for achievements

    Helps contain what each event looks look as a response
    """

    alias Web.ErrorHelpers

    def event("delete", %{ref: ref, achievement: achievement}) do
      %{
        "event" => "achievements/delete",
        "ref" => ref,
        "status" => "success",
        "payload" => %{
          "key" => achievement.key
        }
      }
    end

    def event("errors", %{ref: ref, event: event, changeset: changeset}) do
      errors = Ecto.Changeset.traverse_errors(changeset, &ErrorHelpers.translate_error/1)

      %{
        "event" => event,
        "ref" => ref,
        "status" => "failure",
        "payload" => %{
          "errors" => errors
        }
      }
    end

    def event("not-found", %{ref: ref, event: event}) do
      %{
        "event" => event,
        "ref" => ref,
        "status" => "failure",
        "payload" => %{
          "errors" => %{"key" => ["not found"]}
        }
      }
    end

    def event("sync", %{ref: ref, total: total, achievements: achievements}) do
      %{
        "event" => "achievements/sync",
        "ref" => ref,
        "payload" => %{
          "total" => total,
          "achievements" =>
            Enum.map(achievements, fn achievement ->
              payload("show", %{achievement: achievement})
            end)
        }
      }
    end

    def event("update", %{ref: ref, event: event, achievement: achievement}) do
      %{
        "event" => event,
        "ref" => ref,
        "status" => "success",
        "payload" => payload("show", %{achievement: achievement})
      }
    end

    def payload("show", %{achievement: achievement}) do
      Map.take(achievement, [
        :key,
        :title,
        :description,
        :display,
        :points,
        :partial_progress,
        :total_progress
      ])
    end
  end
end
