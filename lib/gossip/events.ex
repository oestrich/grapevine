defmodule Gossip.Events do
  @moduledoc """
  Contect for managing a game's events
  """

  import Ecto.Query

  alias Gossip.Events.Event
  alias Gossip.Repo

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
  Create a new event for a game
  """
  def create(game, params) do
    game
    |> Ecto.build_assoc(:events)
    |> Event.changeset(params)
    |> Repo.insert()
  end

  @doc """
  Update a game for an event
  """
  def update(event, params) do
    event
    |> Event.changeset(params)
    |> Repo.update()
  end

  @doc """
  Delete an event
  """
  def delete(event) do
    event
    |> Repo.delete()
  end
end
