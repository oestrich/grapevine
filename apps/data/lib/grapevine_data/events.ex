defmodule GrapevineData.Events do
  @moduledoc """
  Contect for managing a game's events
  """

  import Ecto.Query

  alias GrapevineData.Events.Event
  alias GrapevineData.Repo
  alias Stein.Pagination

  @doc """
  New changeset for an event, without a game
  """
  def new() do
    Event.changeset(%Event{}, %{})
  end

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
  Increment view count for event
  """
  def inc_view_count(event) do
    event
    |> Event.inc_view_count_changeset(%{view_count: 1 + event.view_count})
    |> Repo.update()
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
  Return a limited set of events from the next month
  """
  def homepage_events() do
    base_future_query()
    |> limit(3)
    |> Repo.all()
  end

  @doc """
  Get recent events for all games
  """
  def next_month() do
    base_future_query()
    |> preload([:game])
    |> Repo.all()
  end

  defp base_future_query() do
    last_week = Timex.now() |> Timex.shift(weeks: -1)
    one_month_out = Timex.now() |> Timex.shift(months: 1)
    now = Timex.now()

    Event
    |> where([e], (e.start_date >= ^last_week and e.start_date <= ^one_month_out) or e.start_date <= ^now and e.end_date >= ^now)
    |> order_by([e], asc: e.start_date, asc: e.end_date)
  end

  @doc """
  Fetch all events, ordered by start date
  """
  def all(opts \\ []) do
    opts = Enum.into(opts, %{})

    query =
      Event
      |> preload([:game])
      |> order_by([e], desc: e.start_date)

    Pagination.paginate(Repo, query, opts)
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
  Create a new event
  """
  def create(params) do
    changeset = Event.changeset(%Event{}, params)

    case Repo.insert(changeset) do
      {:ok, event} ->
        :telemetry.execute([:grapevine, :game_events, :create, :success], %{count: 1})
        {:ok, event}

      {:error, changeset} ->
        :telemetry.execute([:grapevine, :game_events, :create, :failure], %{count: 1})
        {:error, changeset}
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
