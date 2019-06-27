defmodule Grapevine.Events do
  @moduledoc """
  Contect for managing a game's events
  """

  import Ecto.Query

  alias Grapevine.Events.Event
  alias GrapevineData.Repo

  @doc """
  New changeset for an event
  """
  def new(game) do
    game
    |> Ecto.build_assoc(:events)
    |> Event.changeset(%{})
  end

  @doc """
  Edit changeset for an event
  """
  def edit(event) do
    event
    |> Event.changeset(%{})
  end

  @doc """
  Get all events for a game
  """
  def for(game) do
    Event
    |> where([e], e.game_id == ^game.id)
    |> order_by([e], desc: e.start_date)
    |> Repo.all()
  end

  @doc """
  Get recent events for all games
  """
  def next_month() do
    last_week = Timex.now() |> Timex.shift(weeks: -1)
    one_month_out = Timex.now() |> Timex.shift(months: 1)

    Event
    |> where([e], e.start_date >= ^last_week and e.end_date <= ^one_month_out)
    |> order_by([e], asc: e.start_date, asc: e.end_date)
    |> preload([:game])
    |> Repo.all()
  end

  @doc """
  Get recent events for a game
  """
  def recent(game) do
    last_week = Timex.now() |> Timex.shift(weeks: -1)

    Event
    |> where([e], e.game_id == ^game.id)
    |> where([e], e.start_date >= ^last_week)
    |> order_by([e], asc: e.start_date, asc: e.end_date)
    |> Repo.all()
  end

  @doc """
  Get an event for a user

  Scoped to the user
  """
  def get(user, id) do
    case Repo.get(Event, id) do
      nil ->
        {:error, :not_found}

      event ->
        event = Repo.preload(event, [:game])

        case event.game.user_id == user.id do
          true ->
            {:ok, event}

          false ->
            {:error, :not_found}
        end
    end
  end

  @doc """
  Get an event and preload it
  """
  def get(id) do
    case Repo.get(Event, id) do
      nil ->
        {:error, :not_found}

      event ->
        {:ok, Repo.preload(event, [:game])}
    end
  end

  @doc """
  Get an event and preload it by the uid
  """
  def get_uid(id) do
    case Ecto.UUID.cast(id) do
      {:ok, id} ->
        case Repo.get_by(Event, uid: id) do
          nil ->
            {:error, :not_found}

          event ->
            {:ok, Repo.preload(event, [:game])}
        end

      :error ->
        {:error, :not_found}
    end
  end

  @doc """
  Create a new event for a game
  """
  def create(game, params) do
    changeset =
      game
      |> Ecto.build_assoc(:events)
      |> Event.changeset(params)

    case Repo.insert(changeset) do
      {:ok, event} ->
        :telemetry.execute([:grapevine, :game_events, :create, :success], %{count: 1}, %{game_id: game.id})
        {:ok, event}

      {:error, changeset} ->
        :telemetry.execute([:grapevine, :game_events, :create, :failure], %{count: 1}, %{game_id: game.id})
        {:error, changeset}
    end
  end

  @doc """
  Update a game for an event
  """
  def update(event, params) do
    changeset = event |> Event.changeset(params)

    case Repo.update(changeset) do
      {:ok, event} ->
        :telemetry.execute([:grapevine, :game_events, :update, :success], %{count: 1}, %{
          game_id: event.game_id
        })

        {:ok, event}

      {:error, changeset} ->
        :telemetry.execute([:grapevine, :game_events, :update, :failure], %{count: 1}, %{
          game_id: event.game_id
        })

        {:error, changeset}
    end
  end

  @doc """
  Delete an event
  """
  def delete(event) do
    case Repo.delete(event) do
      {:ok, event} ->
        :telemetry.execute([:grapevine, :game_events, :delete, :success], %{count: 1}, %{
          game_id: event.game_id
        })

        {:ok, event}

      {:error, changeset} ->
        :telemetry.execute([:grapevine, :game_events, :delete, :failure], %{count: 1}, %{
          game_id: event.game_id
        })

        {:error, changeset}
    end
  end
end
